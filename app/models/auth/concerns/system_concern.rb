module Auth::Concerns::SystemConcern

	extend ActiveSupport::Concern

	included do

		include Mongoid::Document
		field :__comments, type: String
		field :address, type: String	
		
	
	end

end