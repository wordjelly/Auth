class Auth::Work::Instruction
	include Mongoid::Document
	include Mongoid::Timestamps
	include Auth::Concerns::Work::CommunicationFieldsConcern
	include Auth::Concerns::ImageLoadConcern
	
	attr_accessor :product_id
	attr_accessor :cart_item_id

	INSTRUCTION_TYPES = ["Before The Test","After The Test","During The Test","Who This Test is For","Who Should Not Take This Test"]

	embedded_in :cart_item, :class_name => Auth.configuration.cart_item_class, :polymorphic => true
	
	embedded_in :product, :class_name => Auth.configuration.product_class, :polymorphic => true

	field :summary_icon_class, type: String

	field :summary_text, type: String

	field :summary_icon_color, type: String

	field :include_in_summary, type: Boolean, default: false

	field :title, type: String

	field :description, type: String

	embeds_many :links, :class_name => "Auth::Work::Link"
	embeds_many :bullets, :class_name => "Auth::Work::Bullet"
	embeds_many :communications, :class_name => "Auth::Work::Communication", :as => :instruction_communications

	########################################################################
	##
	##
	## Overridden methods from communication_fields_concern.rb
	##
	##
	########################################################################
	def get_link(args={})
		if self.product_id
			Rails.application.routes.url_helpers.instruction_url({:product_id => self.product_id, :id => self.id.to_s})
		elsif self.cart_item_id
			Rails.application.routes.url_helpers.instruction_url({:cart_item_id => self.cart_item_id, :id => self.id.to_s})
		end
	end

	## okay let me test upto this point.
	## create a 

end