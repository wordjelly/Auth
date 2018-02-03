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


		## this is expected to be passed into the params by the user, when he is calling refresh_payment.
		## expected to be a string
		## can be "true" or "false"
		## if true -> gateway_callback is ignored, and verify payment is done, and vice versa.
		attr_accessor :is_verify_payment

		##the amount for this payment
		field :amount, type: Float

		##gateway
		##card
		##cash
		##cheque
		field :payment_type, type: String

		## gateway callback called
		field :gateway_callback_called, type: Boolean, default: false


		##the id of the cart for which this payment was made
		field :cart_id, type: String

		## success : 1
		## fail : 0
		## pending : null.
		field :payment_status, type: Integer

		## payment ack proof.
		field :payment_ack_proof, type: String

		
		## is it a refund?
		## true if it is a refund, false otherwise.
		field :refund, type: Boolean

		## the cart associated with this payment
		attr_accessor :cart

		## Hash with two keys:
		## cart => with all its attributes
		## payment => with an array of cart_item objects accepted due to it.
		attr_accessor :payment_receipt
			
		##
		## how much change should be given to the customer.
		##
		field :cash_change, type: Float, default: 0

		validates_presence_of :cart_id
		validates_presence_of :resource_id
		validates_presence_of :amount
		validates_presence_of :payment_type
		validates_presence_of :resource_class
		validate :cheque_or_card_payment_not_excessive
		validates :amount, numericality: { :greater_than => 0.00 }, unless: Proc.new { |document| document.refund  }


		## payment is invalid if the minimum payable amount of the cart is not satisfied.
		

		validate :cart_not_empty
		
		validate :refund_created_or_approved_only_if_balance_is_negative
		validate :refund_approved_if_cart_pending_balance_is_equal_to_refund_amount

		validate :update_cart_items_accepted

		validate :payment_satisfies_minimum_payment_requirement

		before_validation do |document|



			document.set_cart(document.cart_id)
			
			document.payment_callback(document.payment_type,document.payment_params)  
							
			## we can hook the refresh into this.
			document.refresh_refund
			
			



			document.verify_payment
		end

		## because the validation will not allow the payment status to be changed in case this is not an admin user, and we need to allow the user to refresh the payment state, in case of refunds which need to set as failed because some later refund was accepted but in that callback the nil refund was for some reason not set as failed.
		## also in case of gateway payments, we need to allow to see if it can be verified.
		## both these methods change the state of the payment suo moto. it is not necessary that the user should be an admin.
		#after_validation do |document|
		#	if document.errors.full_messages.empty?
				
		#	end
		#end

		before_save do |document|
			if !document.skip_callback?("before_save")

			end
		end

		## when a refund is accepted, any pening refund requests are considered to have failed, since this one has succeeded.
		after_save do |document|
			if !document.skip_callback?("after_save")


				## find all  pending refunds and set them as failed.
				if document.payment_status_changed? && document.payment_status == 1 


					
					if document.refund
						
						## find previous refunds.
						any_pending_refunds = self.class.where(:refund => true, :payment_status => nil)

						
						any_pending_refunds.each do |pen_ref|
							pen_ref.signed_in_resource = document.signed_in_resource
							pen_ref.refund_failed
							## so that it doesnt do this recursively for every refund.
							pen_ref.skip_callbacks = {:after_save => true}
							res = pen_ref.save

						end

					
					end

					## set the payment receipt
					document.set_payment_receipt

				end
			end
		end


		#####################################################
		##
		##
		## DISCOUNT
		##
		##
		#####################################################
			
		## id of discount coupon.
		field :discount_id

		## can be 'verified','pending_verification','verification_denied'
		DISCOUNT_STATUS_VERIFIED = "verified"
		DISCOUNT_STATUS_PENDING_VERIFICATION = "pending_verification"
		DISCOUNT_STATUS_VERIFICATION_DENIED = "verification_denied"

		field :discount_status, type: String



	end

	module ClassMethods
		def find_payments(resource,cart)
			res = Auth.configuration.payment_class.constantize.where(:resource_id => resource.id.to_s, :cart_id => cart.id.to_s)
			res.each do |p|
				#puts "found payment: #{p.id.to_s}"
			end
		end

			
	end

	

	
	## basically checks if there is any refund that was accepted after this refund_request was created. then in that case sets this refund as failed.
	## this is basically done because while normally, whenever a refund is accepted, all other pending refunds are updated as failed, but suppose that that operation does not complete and some refunds are left still pending.
	## then in the controller update action, this method is called on the payment.
	def refresh_refund
		
		if self.refund && self.payment_status.nil?
			
			already_accepted_refunds = self.class.where(:refund => true, :payment_status => 1, :updated_at => { :$gte => self.created_at})
			
			if already_accepted_refunds.size > 0
				
				self.refund_failed
			end
		end
	end
		
	## returns the cart_item ids which were accepted due to this payment.
	## called after_save callback.
	## called in show action of controller.
	## return[Array]
	def set_payment_receipt
		self.payment_receipt = {:current_payment => [], :cart => {}}
		Auth.configuration.cart_item_class.constantize.where(:accepted_by_payment_id => self.id.to_s).each do |c_item|
			self.payment_receipt[:current_payment] <<  c_item
		end
		set_cart(self.cart_id) if self.cart.nil?
		self.payment_receipt[:cart] = self.cart.prepare_receipt
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
		
		if self.refund
			self.send("refund_callback",params,&block) 
		elsif self.discount_id
			self.send("discount_callback",params,&block)
		else
			self.send("#{type}_callback",params,&block) if self.respond_to? "#{type}_callback"
		end

		yield if block_given?
	end

	def payment_excessive?
		self.amount > self.cart.cart_pending_balance && self.amount > 0
	end

	## the if new_record? is added so that the callback is done only when the payment is first made and not every time the payment is updated
	## calculate the change
	## make the amount equal to the pending balance if it is excesive.
	def cash_callback(params,&block)
		if self.new_record?
			calculate_change
			self.amount = self.cart.cart_pending_balance if payment_excessive?
		end
	end


	## sets the change to be given to the customer
	## @used_in : cash_callback
	## @return[nil] : returns nothing, just sets the cash_change attribute.
	def calculate_change
		## by this point in time the cart has already been set, and prepared, so we know the total pending amount. 
		if self.amount > self.cart.cart_pending_balance
			self.cash_change = self.amount - self.cart.cart_pending_balance
		else
			self.cash_change = 0
		end
	end

	## the if new_record? is added so that the callback is done only when the payment is first made and not every time the payment is updated
	def cheque_callback(params,&block)
		
	end

	
	def refund_callback(params,&block)
		
	end

	def refund_success
		self.amount = self.cart.refund_amount
		self.payment_status = 1
	end

	
	def refund_failed
		self.amount = 0
		self.payment_status = 0
	end

	## the if new_record? is added so that the callback is done only when the payment is first made and not every time the payment is updated
	def card_callback(params,&block)
		
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
	def gateway_callback(params,&block)
		## if its a new_record we don't do any callback, because the payment doesnt exist to check it .
		## if the user has passed in is_verify_payment, we still don;t do this callback, because 
		return if (self.new_record? || self.is_verify_payment == "true") 

		yield if block_given?
	end

	def discount_callback

		## the callback should fire on create/update, so new_record checking is not required.

		## first check if the discount id exists -> get the discount object.
		
		begin
			discount_obj = Auth.configuration.discount_class.constantize.find(discount_id)
			if discount_obj.requires_verification == true
				if discount_obj.pending_verification_payment_ids[self.id.to_s]
				elsif discount_obj.verified_payment_ids[self.id.to_s]
					self.payment_status = 1
				else
					## we need to add it to the discount obj for pending ids.
					## and also send a message to the owner of the discount object to verify it
					#Auth.configuration.discount_class.
					# Topic.where({"$and" => [{"gar" => {"$ne" => "hello"}}]}).count
				end
			end
		rescue

		end
		
		## now verify that the discount amount <=> correlates with the payment amount
		## check that the amount == discount_amount / the discount_percentage*(cart_pending_balance)
		## if not then do nothing.

		## then check whether it needs verification
		## then check if it is already verified.
		## then find and update where the present payment id does not exist in the pending, or the verified blocks.
		## then do nothing =>  
		## if verification is not needed, then simply set the payment status to 1. 
	

	end
	

	def physical_payment?
		is_card? || is_cash? || is_cheque?
	end

	
	def verify_payment
		if self.new_record?
			return nil
		else
			if self.is_verify_payment == "true"
				if self.payment_pending
					return true
				else
					return nil
				end
			else
				return nil
			end
		end
		
	end

	## finds the cart that this payment refers to
	## sets it to an attr_accessor called cart
	## prepares the cart(refer to cart concern for a description of this method)
	def set_cart(cart_id)	
		
		
		self.cart = Auth.configuration.cart_class.constantize.find(cart_id)
	

		
		self.cart.prepare_cart
		



	end

	## is called on payment_status_changed
	## check whether this payment was already registered on the cart as success or failed.
	## and then debit/credit.
	## return[Boolean] : true/false depending on whether all the cart items could be successfully updated or not. 
	def update_cart_items_accepted
		
		if payment_status_changed?

			if payment_status == 1
				self.cart.cart_credit+= self.amount
			elsif payment_status == 0 && payment_status_was == 1
				
				self.cart.cart_credit-= self.amount
			else

			end

		

			cart_item_update_results = self.cart.get_cart_items.map{|cart_item| 
				cart_item.signed_in_resource = self.signed_in_resource
				cart_item.set_accepted(self,nil)
			}.compact.uniq
			self.errors.add(:cart,"cart item status could not be updated") if cart_item_update_results[0] == false
			
		end
		
	end	

	#######################################################
	##
	## CUSTOM VALIDATION DEFS
	##
	#######################################################

	## validation
	def cheque_or_card_payment_not_excessive
		
		self.errors.add(:amount,"payment is excessive") if payment_excessive? && (is_cheque? || is_card?) && !refund
	end

	## validation
	def cart_not_empty
		return if self.refund == true
		self.errors.add(:cart,"cart has to have some items in order to make a payment") if !self.cart.has_items?

	end

=begin
	## not really a validation, basically doesnt allow any user provided attributes to be set if the user is not an admin and trying to update the document.
	def document_updated_only_by_admin
		if !new_record?
			if !signed_in_resource.is_admin? 
				self.attributes.clear
			end
		end

	end

	## validation
	def document_status_set_only_by_admin
		if payment_status_changed?
			if !signed_in_resource.is_admin?
				## delete the payment_status if resource is not an admin, whether he is saving or updating the document.
				self.attributes.delete("payment_status")
				self.errors.add(:payment_status,"only admin can set or change the payment status")
			end
		end
	end
=end

	## validation
	def refund_created_or_approved_only_if_balance_is_negative
		if refund
			## in case the admin wants to mark a refund as failed.
			if payment_status == 0 && payment_status_changed?
			
			else
				self.errors.add("payment_status","you cannot authorize a refund since the pending balance is positive.") if self.cart.cart_pending_balance >= 0
			end
		end
	end

	## validation 
	def refund_approved_if_cart_pending_balance_is_equal_to_refund_amount
		if payment_status_changed? && payment_status == 1 && refund
			self.errors.add("payment_status","you cannot authorize a refund since the amount you entered is wrong") if self.cart.cart_pending_balance != self.amount
		end
	end

	## validation
	def payment_satisfies_minimum_payment_requirement
		self.cart.prepare_cart
		return if self.refund == true  
		self.errors.add("amount","payment amount is not sufficient") if (self.cart.cart_minimum_payable_amount.nil? || (self.cart.cart_minimum_payable_amount > self.amount))
	end

	def as_json(options={})
		super(options).merge({:payment_receipt => self.payment_receipt,:cash_change => self.cash_change})
	end

end


