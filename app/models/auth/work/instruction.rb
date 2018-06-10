class Auth::Work::Instruction
	include Mongoid::Document
	embedded_in :product, :class_name => Auth.configuration.product_class
end