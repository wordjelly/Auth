module Auth::Concerns::WorkflowConcern

	extend ActiveSupport::Concern

	included do

		include Mongoid::Document
  	include Auth::Concerns::OwnerConcern


    field :resolve, type: Boolean, default: false

    field :time_information, type: Hash

    field :location_information, type: Hash

    field :resolved_location_id, type: String

    field :resolved_time, type: Integer

    field :calculated_duration, type: Integer

    field :duration, type: Integer

    ## we need to provide a duration calculation function here.
    field :duration_calculation_function, type: String, default: ""



    ## this can be set, depending upon where what and how.

    def resolve_location(location_information={},time_information={},resolved_location_id=nil,resolved_time=nil)
      ## if the self class is a requirment, then merge in the location information in case this is empty.
      
      return unless self.resolve
      ## given the location information, resolve the nearest location.
      ## search for it, and store the location id.
    end


    def resolve_time(location_information={},time_information={},resolved_location_id=nil,resolve_timed=nil)
      return unless self.resolve
      ## based on the time preferences, fix on a time.
    end


    def calculate_duration
      return if self.duration
      ##otherwise eval the calcu
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