class Auth::Work::Instruction
	include Mongoid::Document

	INSTRUCTION_TYPES = ["Before The Test","After The Test","During The Test","Who This Test is For","Who Should Not Take This Test"]

	embedded_in :product, :class_name => Auth.configuration.product_class

	field :instruction_type, type: String
	validates_presence_of :instruction_type

	field :title, type: String

	embeds_many :bullets, :class_name => "Auth::Work::Bullet"

end