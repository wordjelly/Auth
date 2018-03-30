module Auth::Concerns::WorkflowConcern

	extend ActiveSupport::Concern

	included do

		include Mongoid::Document
  	include Auth::Concerns::OwnerConcern


    field :resolve, type: Boolean, default: false


    ## must have a start_time and an end_time
    ## or these will have to be calculated.
    ## start_time is the 
    ## dont specify these in the time information, if you want it to just continue relative to the first step.
    ## this should be added to the requirement during the resolve phse.
    field :time_information, type: Hash

    field :location_information, type: Hash

    field :resolved_location_id, type: String

    field :resolved_time, type: Integer

    field :calculated_duration, type: Integer

    field :duration, type: Integer

    ## we need to provide a duration calculation function here.
    field :duration_calculation_function, type: String, default: ""

    field :category, type: Array

    field :resolved_id, type: String

    def generate_location_query

      query_clause = {}

      if resolved_location_id
        
        query_clause = {
          "location_id" => resolved_location_id
        }
      
      elsif self.location_information[:location_point_coordinates] && self.location_information[:within_radius]
      
        query_clause = {
          "location" => {
            "$nearSphere" => {
              "$geometry" => {
                "type" => "Point",
                "coordinates" => self.location_information[:location_point_coordinates]
              },
              "$maxDistance" => self.location_information[:within_radius] * 1609.34
             }
          }
      }

      end

      return query_clause

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
    def resolve_location(location_information={},time_information={},resolved_location_id=nil,resolved_time=nil)


      ## merge in the location information in case we don't have any location information.

      unless self.location_information[:location_id]

        self.location_information[:location_id] = location_information[:location_id] if location_information[:location_id]
      
      end

      unless (self.location_information[:within_radius] || self.location_information[:location_point_coordinates])

        if (location_information[:within_radius] && location_information[:location_point_coordinates])

            self.location_information[:within_radius] = location_information[:within_radius]

            self.location_information[:location_point_coordinates] = location_information[:location_point_coordinates]

        end

      end

      return unless self.resolve
  
      ## so we should call on self only.
      location_query = generate_location_query

      ## who to search for ?
      ## the location class.

      if results = Auth.configuration.location_class.constantize.where(location_query)

        self.resolved_location_id = results.first.id.to_s

      end

    end

    ### @param[Hash] location_information : provided location_information to merge in case the present location information is deemed to be insufficient.
    ## @param[Hash] time_information : provided time_information to merge in case the present time information is deemed to be insufficient.
    ## @param[String] resolved_location_id : the resolved_location_id of the present step.
    ## @param[Integer] resolved_time : the resolved_time of the present_step
    ## will merge the time information for start time and end time from the previous step in case these are not defined on the present step.
    ## if time information is missing, then use the provided time information. 
    def resolve_time(location_information={},time_information={},resolved_location_id=nil,resolved_time=nil)

      self.time_information.merge(time_information) if ((self.time_information[:start_time].blank? || self.time_information[:end_time].blank?) && self.resolved_time.blank?) 


      return unless self.resolve
      
      ## resolved time is basically just set if it is passed into the time information.
      self.resolve_time = self.time_information[:resolved_time] if self.time_information[:resolved_time]

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