##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::PaymentConcern

	extend ActiveSupport::Concern
		
	include Auth::Concerns::ChiefModelConcern
	include Auth::Concerns::OwnerConcern
	
	included do 

		FAILED = "Failed"
		SUCCESS = "Success"
		PENDING = "You need to complete this payment"



		##the amount for this payment
		field :amount, type: Float

		##gateway
		##card
		##cash
		##cheque
		field :payment_type, type: String

		##the id of the cart for which this payment was made
		field :cart_id, type: String

		## can be "success"
		## can be "faphysical_paymented"
		## set in respective callback method of payment_type
		field :payment_status, type: Integer

		## payment ack proof.
		field :payment_ack_proof, type: String

		## validator is called on the payment_ack_proof, in this method.
		## override as needed.
		validate :payment_has_ack_proof
		validates_presence_of :cart_id
		validates_presence_of :resource_id
		validates_presence_of :amount
		validates_presence_of :payment_type

		##after the cart receives a payment
		##it has to be determined now if the order can go through or not.
		##this whole thing has to happen on the cart object
		##and also is a feature of the products that make up the cart.
		##so the cart has to have some kind of order status.
		##and that will have to be reflected onto the cart_items
		##however even after cart is created , for eg he may choose to pay after order is delivered, cheque, or card.
		##in that case all this should happen on cart_show.
		##so after payment is created, give a link to go and see the cart.
		
	end

	module ClassMethods
		def find_payments(resource,cart)
			puts "came to find payments with resource; #{resource.id.to_s}"
			puts "and cart: #{cart.id.to_s}"
			res = Auth.configuration.payment_class.constantize.where(:resource_id => resource.id.to_s, :cart_id => cart.id.to_s)
			res.each do |p|
				puts "found payment: #{p.id.to_s}"
			end
		end		
	end

	##res : 59a5405c421aa90f732c9059
	##cart : 59a54d7a421aa9173c834728
	
	##used in pay_u_money_helper.rb
	def get_cart_name
		cart = Auth.configuration.cart_class.constantize.find(cart_id)
		cart.name || "shopping cart"
	end

	def is_gateway?
		payment_type && payment_type == "gateway"
	end

	def is_cash?
		payment_type && payment_type == "cash"
	end

	def is_card?
		payment_type && payment_type == "card"
	end

	def is_cheque?
		payment_type && payment_type == "cheque"
	end

	def cash_callback(params)
		self.payment_status = 1
	end

	def cheque_callback(params)
		self.payment_status = 1
	end

	def card_callback(params)
		self.payment_status = 1
	end

	def payment_failed
		payment_status && payment_status == 0
	end

	def payment_success
		payment_status && payment_status == 1
	end

	def payment_pending
		!payment_status
	end

	##override this method depending upon the gateway that you use.
	##
	def gateway_callback(params)

	end
	
	def physical_payment?
		is_card? || is_cash? || is_cheque?
	end

	## returns true if this payment needs some kind of written proof / acknoledgement from the receiver of the payment. eg a signed receipt aknowledgin that the payment was received.
	## override as needed.
	def needs_proof?
		##lets assume that we have a cart item, that is a salary.
		##so the cart item should be able to dictate this aspect.
		physical_payment?
	end

	## checked if the payment is acked
	## just now just a dummy placeholder checks if the ack_proof length is > 5.
	def payment_has_ack_proof
		if needs_proof?
			payment_ack_proof.length > 5
		end
	end

	## currently does nothing
	## overridden in the payment gateway to verify payments that have not be either success or failure.
	def verify_payment

	end

	



end
