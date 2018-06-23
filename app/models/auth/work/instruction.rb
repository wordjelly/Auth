class Auth::Work::Instruction
	include Mongoid::Document
	include Auth::Concerns::ChiefModelConcern

	attr_accessor :product_id

	INSTRUCTION_TYPES = ["Before The Test","After The Test","During The Test","Who This Test is For","Who Should Not Take This Test"]

	embedded_in :product, :class_name => Auth.configuration.product_class

	field :summary_icon_class, type: String

	field :summary_text, type: String

	field :summary_icon_color, type: String

	field :include_in_summary, type: Boolean, default: false

	field :title, type: String

	field :description, type: String

	embeds_many :links, :class_name => "Auth::Work::Link"
	embeds_many :bullets, :class_name => "Auth::Work::Bullet"
	embeds_many :communications, :class_name => "Auth::Work::Communication", :as => :instruction_communications

end