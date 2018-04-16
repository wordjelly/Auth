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
    ## eg : [[year,month,weekday,range_beginning,range_ending]..]
    ## eg : [[*,2,*,seconds_since_12_am,seconds_since_start]] : star means all values are permitted for that unit. and 2.30 -> 4.30 is the allowed time for this thing.  
    ## :minimum_time_after_previous_step -> number of seconds after previous step's end_time that this thing can start. These many seconds have to elapse.
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
    ## @param[Hash] time_information : the time information of the present step.
    ## @param[String] resolved_location_id : the resolved_location_id of the present step.
    ## @param[Integer] resolved_time : the resolved_time of the present_step
    ## will first check if a location_id is already present in the current location_information.
    ## if yes, will do nothing.
    ## if no, will assign the location_id from the provided location_information hash.
    ## next will check if within_radius and location_point_coordinates are already present in the location_information otherwise will try to assing from the provided location_information hash.
    ## at this point, will look whether this location needs to be resolved or not, and if not then will return.
    ## if it needs to be resolved, it will call the generate_location_query, using the location information now assigned, and will assign a location id based on the results of that query.
    ## the time_information and resolved_time params are not used.!
    def resolve_location(location_information={},time_information={},resolved_location_id=nil,resolved_time=nil)

      self.location_information.deep_symbolize_keys!

      self.location_information[:location_id] ||= location_information[:location_id]

      self.location_information[:within_radius] ||= location_information[:within_radius]

      self.location_information[:location_point_coordinates] ||= location_information[:location_point_coordinates]

      self.location_information[:location_categories] ||= location_information[:location_categories]

      
      return unless self.resolve
    
      
        
      if self.location_information[:location_id]
        ## the result is to just find
        self.resolved_location_id = Auth.configuration.location_class.constantize.find(self.location_information[:location_id]).id.to_s
        
      
      elsif (self.location_information[:location_point_coordinates] && self.location_information[:within_radius])
  
          ## what if it is just a location category?
          ## we cannot query just on a location category.
          ## so if there is a category, then add it to 
          ## so here we can do the query.
          query = generate_location_query(self.location_information[:location_point_coordinates],self.location_information[:within_radius],self.location_information[:location_categories]) 

         # puts "the query is:"
         # puts query.to_s
          results = Auth.configuration.location_class.constantize.where(query)
         # puts "the results size is:"
         # puts results.size.to_s
          
          self.resolved_location_id = results.first.id.to_s if results.size > 0
          
      end
        


    end

    
    def resolve_time(previous_step_time_information)


      if self.time_information[:start_time_specification]
        
        raise("minimum time since previous step is absent") unless self.time_information[:minimum_time_since_previous_step]        
        if previous_step_time_information

          time_range_based_on_previous_step = previous_step_time_information[:end_time_range].map{|c| c = c + self.time_information[:minimum_time_since_previous_step]}

          range_size_in_seconds = time_range_based_on_previous_step[1] - time_range_based_on_previous_step[0]
          
          start_time = Time.at(time_range_based_on_previous_step[0])
          
          start_time_day_beginning = start_time.beginning_of_day 

          start_time_as_strftime = start_time.strftime('%Y %-m %w').split("\s")

          start_time_as_strftime << start_time -start_time_day_beginning

          start_time_as_strftime << range_size_in_seconds

          matched = true

          self.time_information[:start_time_specification].each_with_index {|spec,key|
            
            spec[0..2].each_with_index{|unit,u_key|
              
              if unit=~/\*/

              else
                matched = false if unit != start_time_as_strftime[u_key]
              end
            }

            ## at this stage if matched is true, then check the fourth and the fifth argument 
            next if matched == false

            matched = false unless ((spec[3].to_i < start_time_as_strftime[3].to_i) && (start_time_as_strftime[3].to_i < start_time_as_strftime[4].to_i) && (start_time_as_strftime[4].to_i < spec[4].to_i))
            
          }

          raise "does not satisfy the start time specification" if matched == false

          self.time_information[:start_time_range] = time_range_based_on_previous_step

          self.time_information[:end_time_range] = self.time_information[:start_time_range].map{|c| c = c + self.duration}

        else
            
          ## we consider the earliest specification.
          specification = self.time_information[:start_time_specification][0]
   
          t = Time.now
          year = t.strftime("%Y")
          month = t.strftime("%-m")
          day_of_week = t.strftime("%w")

          ## replace all the stars in the first three things in the specification , with the relevant unit from the current time.
          ## eg. if year is * then replace it with the current year.
          ymd = specification[0..2].map.each_with_index{|value,key|
            value.gsub!(/\*/) { |match| 
                if key == 0
                  match = year
                elsif key == 1
                  match = month
                elsif key == 2
                  match = day_of_week
                end
            }
            value
          }

          
          ## now convert this into a datetime.
          puts "ymd joint : #{ymd.join(' ')}"
          t = DateTime.strptime(ymd.join(" "), '%Y %m %w')


          ## add the seconds since the beginning of the day to this.
          t = t + specification[3].to_i

          ## the start time range becomes the time + the seconds to be added onto it, as defined in the specification.
          self.time_information[:start_time_range] = [t.to_i,t.to_i + specification[4].to_i]

          ## and the end_time_range becomes as usual the start_time _+ the duration.
          self.time_information[:end_time_range] = self.time_information[:start_time_range].map{|c| c = c + self.duration}

        end
        
      else
        raise "previous step time information absent" unless (previous_step_time_information && previous_step_time_information[:start_time_range])
        self.time_information[:start_time_range] = previous_step_time_information[:end_time_range]
        self.time_information[:end_time_range] = self.time_information[:start_time_range].map{|c| c = c + self.duration}
      end  

  
    end


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