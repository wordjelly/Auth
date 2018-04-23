module Auth::Concerns::WorkflowConcern

	extend ActiveSupport::Concern

	included do

		include Mongoid::Document
  	include Auth::Concerns::OwnerConcern


    field :resolve, type: Boolean, default: false


    ## three keys are possible
    ## :duration -> time in seconds of this thing.
    ## :start_time_range -> the absolute time in epoch when this thing can start ([from,to])
    ## :end_time_range -> the absolute time in epoch when this thing can end ([from,to])
    ## :start_time_specification -> 
    ## eg : [[year,month,day_of_month,weekday,range_beginning,range_ending]..]
    ## eg : [[*,2,*,*,seconds_since_12_am,seconds_since_start]] : star means all values are permitted for that unit. and 2.30 -> 4.30 is the allowed time for this thing.  
    ## :minimum_time_after_previous_step -> number of seconds after previous step's end_time that this thing can start. These many seconds have to elapse.
    ## :maximum_time_after_previous_step -> the maximum number of seconds that can elapse after the previous step for this step to start.
    field :time_information, type: Hash, default: {}

    field :location_information, type: Hash, default: {}

    field :resolved_location_id, type: String

    field :resolved_time, type: Integer

    field :calculated_duration, type: Integer

    field :duration, type: Integer

    ## we need to provide a duration calculation function here.
    field :duration_calculation_function, type: String, default: ""

    field :category, type: Array, default: []

    field :resolved_id, type: String

    ## @param[Hash] location_coordinates : expected of the format {:lat => float, :lng => float}
    ## @param[Array] within_radius : integer
    ## @param[Array] location_categories : 
    def generate_location_query(location_coordinates,within_radius,location_categories=nil)
      
    
      point = Mongoid::Geospatial::Point.new(location_coordinates[:lng],location_coordinates[:lat])

      query_clause = {
        "$and" => [
          {
            "location" => {
              "$nearSphere" => {
                "$geometry" => {
                    "type" => "Point",
                    "coordinates" => point
                },
                "$maxDistance" => within_radius * 1609.34
              }
            }
          }
        ]
      }

      query_clause["$and"] << {
        "location_categories" => {
          "$in" => location_categories
        }
      } if location_categories

      query_clause
      
    end


    def generate_time_query

      query_clause = {}

      if self.resolved_time
        query_clause =  {
          "time" => self.resolved_time
        }
      elsif self.time_information[:start_time] && self.time_information[:end_time]
        query_clause =  {
          "time" => {
            "$gte" => self.time_information[:start_time],
            "$lte" => self.time_information[:end_time]
          }
        }
      end


      return query_clause

    end


    ### @param[Hash] location_information : the location information of the present step.
    ## will copy over 'location_id','within_radius' and location_point_coordinates if these are not already specified.
    def resolve_location(location_information={})

        self.location_information.deep_symbolize_keys!

        self.location_information[:location_id] ||= location_information[:location_id]
        
        self.location_information[:within_radius] ||= location_information[:within_radius]

        self.location_information[:location_point_coordinates] ||= location_information[:location_point_coordinates]
      
        self.location_information[:location_categories] ||= location_information[:location_categories]

     
    end


    def get_nearest_instant(spec,range)
      
      year = nil
      month = nil
      day_of_week = nil
      day_of_month = nil
      date_specs = {}
     
      regex_pattern = ""
      spec[0..3].map.each_with_index{|value,key|
          if value =~ /\*/
            regex_pattern += "[0-9]{4}" if key == 0
            regex_pattern += "[0-9]{2}" if key == 1
            regex_pattern += "[0-9]{2}" if key == 2
            regex_pattern += "[0-9]{1}" if key == 3
          else
            regex_pattern += value
          end
      }
        
      #puts "this is the strftime format."
      #puts $time_hash_strftime_format.to_s

      #puts "the regex pattern is:"
      #puts regex_pattern.to_s

      from_index = $day_id_hash[Time.now.strftime($time_hash_strftime_format)]
      
      #puts "from index is: #{from_index}"

      nearest_instant = nil
      
      $date_hash.keys[from_index..-1].each do |dt|
        nearest_instant = $date_hash[dt] if (dt=~/#{regex_pattern}/ && (range[0] <= $date_hash[dt]) && ($date_hash[dt] <= range[1]))
        break if nearest_instant
      end

      nearest_instant
      
    end

   
    def resolve_start_time(previous_step_time_information)


      if self.time_information[:start_time_specification]
        
        raise("minimum time since previous step is absent") unless self.time_information[:minimum_time_since_previous_step] 
        
        raise("maximum time since previous step is absent") unless self.time_information[:maximum_time_since_previous_step]

        if !previous_step_time_information.empty?

          #puts "previous step time information is:"
          #puts previous_step_time_information.to_s

          time_range_based_on_previous_step = previous_step_time_information[:end_time_range].map{|c| c = c + self.time_information[:minimum_time_since_previous_step]}

          time_range_based_on_previous_step_maximum = 
            previous_step_time_information[:end_time_range].map{|c| c = c + self.time_information[:maximum_time_since_previous_step]}

          range_width = time_range_based_on_previous_step[1] - time_range_based_on_previous_step[0]

          start_time = get_nearest_instant(self.time_information[:start_time_specification],[time_range_based_on_previous_step[0],time_range_based_on_previous_step_maximum[0]])

          ## now we want to know which of these start times, is falling in our start time range, take the earliest one of all.

          raise "does not satisfy the start time specification" unless start_time

          self.time_information[:start_time_range] = [start_time,start_time + range_width]

          

        else
            
          
          t = get_nearest_instant(self.time_information[:start_time_specification],[Time.now.to_i,(Time.now + 5.years).to_i])
  
          raise "Could not find a satsifactory time instant" unless t

          self.time_information[:start_time_range] = [t.to_i,t.to_i + self.time_information[:start_time_specification][5].to_i]


        end
        
      else
        ## okay so imagine we are at the first step of a stage, and there is no previous step ?
        ## how do we know the previous step?
        ## well here that would mean the cart items already there.
        ## this should have come from the cart_item_latest_time.
        
        raise "previous step time information absent" unless (previous_step_time_information && previous_step_time_information[:start_time_range])
        self.time_information[:start_time_range] = previous_step_time_information[:end_time_range].map{|c| c = c + self.time_information[:minimum_time_since_previous_step]}
        
      end  

    end

    def resolve_end_time
      self.time_information[:end_time_range] = self.time_information[:start_time_range].map{|c| c = c + self.duration}
    end

    ## here we should have a calculate simultaneous requirement at the prescribed location, using the requirement ids.



    def calculate_duration
      return if self.duration
      ##to do this, you will need to tell the function how to process. this.
      eval(self.duration_calculation_function)
    end

    ## @param [Hash] permitted_param : the permitted params passed in to the #update_with_conditions def.
    ## @param[Array] locked_fields : an array of field names as strings, denoting which fields cannot be changed in case an order has already been added to the 
    ## @return[Boolean] true/false : whether the permitted params contain any of the locked fields, and if yes, then the query has to be modified to include that there should be no orders in any sop. 
    def self.permitted_params_contain_locked_fields(permitted_params)
      
      locked_fields = self::FIELDS_LOCKED_AFTER_ORDER_ADDED
      result = false
      permitted_params.keys.each do |attr|
        if locked_fields.include? attr.to_s
          result = true
          break
        end
      end
      result
    end

	end

end