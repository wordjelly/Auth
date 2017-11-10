##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::PaymentConcern

	extend ActiveSupport::Concern
		
	include Auth::Concerns::ChiefModelConcern
	include Auth::Concerns::OwnerConcern
	
	included do 

		FAILED = "Failed"
		SUCCESS = "Success"
		PENDING = "You need to complete this payment"


		## the params that are passed into the payment controller at create or update.
		## used in the before_update callback
		## for the gateway_callback
		## in that callback we need access
		## to the full params hash.
		## so this accessor is set in the controller #update
		## and #create methods.
		attr_accessor :payment_params

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


		attr_accessor :cart
		
		validates_presence_of :cart_id
		validates_presence_of :resource_id
		validates_presence_of :amount
		validates_presence_of :payment_type
		validates_presence_of :resource_class


		before_save do |document|
			document.set_cart(document.cart_id) 
			document.payment_callback(document.payment_type,document.payment_params) do 
					document.update_cart_items_accepted if document.payment_status_changed?
			end
		end

		
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
		self.cart.nil? ? "shopping_cart" : (self.cart.name.nil? ? "shopping_cart" : self.cart.name)
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

	def payment_callback(type,params,&block)
		self.send("#{type}_callback",params,&block) if self.respond_to? "#{type}_callback"
	end

	def cash_callback(params,&block)
		return unless self.new_record?
		self.payment_status = 1
		yield if block_given?
	end

	def cheque_callback(params,&block)
		return unless self.new_record?
		self.payment_status = 1
		yield if block_given?
	end

	def card_callback(params,&block)
		return unless self.new_record?
		self.payment_status = 1
		yield if block_given?
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
	def gateway_callback(params,&block)
		return if self.new_record?
		yield if block_given?
	end
	
	def physical_payment?
		is_card? || is_cash? || is_cheque?
	end

	## currently does nothing
	## overridden in the payment gateway to verify payments that have not be either success or failure.
	def verify_payment

	end

	## finds the cart that this payment refers to
	## sets it to an attr_accessor called cart
	## prepares the cart(refer to cart concern for a description of this method)
	def set_cart(cart_id)	
		
		self.cart = Auth.configuration.cart_class.constantize.find(cart_id)
		
		self.cart.prepare_cart(get_resource)

	end

	## is called on payment_status_changed
	## check whether this payment was already registered on the cart as success or failed.
	## and then debit/credit.
	## return[Array] : cart_item instances, after setting stage.
	def update_cart_items_accepted

		if payment_status == 1
			self.cart.cart_credit+= self.amount
		elsif payment_status == 0 && payment_status_was == 1
			self.cart.cart_credit-= self.amount
		else

		end

		self.cart.get_cart_items(get_resource).map{|cart_item| 

			cart_item.set_accepted(self.cart,get_resource,false)

		}
	end	


end

## payment created -> success -> update as success.
## payment updated -> success -> do so.
