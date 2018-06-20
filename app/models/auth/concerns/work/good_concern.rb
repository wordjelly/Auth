## intended to be mixed into the product_class
## contains methods assuming that an item is going to be processed by using the modules provided by the work concern.
module Auth::Concerns::Work::GoodConcern

	extend ActiveSupport::Concern
	
	included do 	
		embeds_many :parameters, :class_name => "Auth::Work::Parameter"
		embeds_many :instructions, :class_name => "Auth::Work::Instruction"
		embeds_many :actors, :class_name => "Auth::Work::Actor"
		embeds_many :variables, :class_name => "Auth::Work::Variable"	

		after_initialize do |document|
			document.summary = document.build_summary
		end

		attr_accessor :summary
		
	end

	def build_summary
		self.summary = []
		self.instructions.each do |inst|
			self.summary << {
				:summary_icon_class => inst.summary_icon_class,
				:summary_text => inst.summary_text,
				:summary_icon_color => inst.summary_icon_color
			} if inst.include_in_summary == true
		end
	end

	def as_json(options)
	  ## includes the images associated with the object as well.
	  super({:methods => [:embedded_document_path, :embedded_document, :summary, :images]}.merge(options))
	end

end