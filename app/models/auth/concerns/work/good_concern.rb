## intended to be mixed into the product_class
## contains methods assuming that an item is going to be processed by using the modules provided by the work concern.
module Auth::Concerns::Work::GoodConcern

	extend ActiveSupport::Concern
	
	included do 	
		embeds_many :parameters, :class_name => "Auth::Work::Parameter"
		embeds_many :instructions, :class_name => "Auth::Work::Instruction"
		embeds_many :actors, :class_name => "Auth::Work::Actor"
		embeds_many :variables, :class_name => "Auth::Work::Variable"
		
	end

end