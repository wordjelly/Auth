module Auth::Concerns::Shopping::PayUMoneyConcern

	extend ActiveSupport::Concern
	
	include Auth::Concerns::ChiefModelConcern	

	included do 
		field :firstname, type: String
		field :email, type: String
		field :phone, type: String
		##same as the payment id.
		field :txnid, type: String
		field :surl, type: String
		field :furl, type: String
		##same as the cart name
		field :productinfo, type: String
		##amount is not added here, because it is already a part of the payment_concern
		##the hash calculated by using the payumoney library.
		field :hast, type: String

		before_save do |document|
			document.calculate_hash 
		end

		##add a validation, that checks that each of the 7 required fields are present, before create, only when the payment_type is gateway.
		##the is_gateway? method is defined in payment_concern.
		##these validations are run before the before_save is called.
		##so will throw an error if either of the following are not present.
		validates_presence_of   :firstname, if: :is_gateway?
		validates_presence_of   :email, if: :is_gateway?
		validates_presence_of   :phone, if: :is_gateway?
		validates_presence_of   :txnid, if: :is_gateway?
		validates_presence_of   :surl, if: :is_gateway?
		validates_presence_of   :furl, if: :is_gateway?
		validates_presence_of 	:productinfo, if: :is_gateway?

	end

	##needs to use the payumoney library.
	def calculate_hash
		options = {:firstname => firstname, :email => email, :phone => phone, :txnid => txnid, :surl => surl, :furl => furl, :productinfo => productinfo, :amount => amount}
		service = PayuIndia::Helper.new(payment_gateway_key, payment_gateway_salt, options)
		self.hast = service.generate_checksum
	end

	def payment_gateway_key
		Auth.configuration.payment_gateway_info[:key]
	end


	def payment_gateway_salt
		Auth.configuration.payment_gateway_info[:salt]
	end



end