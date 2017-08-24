##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::CartItemConcern



	extend ActiveSupport::Concern
	
	include Auth::Concerns::Shopping::ProductConcern

	included do 

		validate :resource_id_not_changed

		##the id of the product to which this cart item refers.
		##permitted
		field :product_id, type: String

		##the user id who is buying this product.
		##not permitted
		field :resource_id, type: String
			
		##the number of this product that are being added to the cart
		##permitted
		field :quantity, type: Integer, default: 1

		##when it is paid for, a transaction should get generated.
		##not permitted
		field :parent_id, type: String

		##name of transaction
		field :parent_name, type: String

		##notes on transaction
		field :parent_notes, type: String

		##is it being discounted, can be from 0 -> 100 percent discount
		##not permitted
		field :discount, type: Float

		##discount code to offer discounts
		##permitted
		field :discount_code, type: String

	################ PAYMENT RELATED FIELDS ################

		##### =>  waiting_to_confirm
		##### =>  confirmed
		##### =>  pending_amount
		##### =>  paid
		##### =>  payment acknowledged
		##### =>  refund_requested
		##### =>  refund_request_accepted
		##### =>  pending_refund
		##### =>  refund_completed
		##### =>  refund_acknowledged
		##### => these states should be set in an after_create callback, it has to be decided if it can be confirmed or not.
		##### => that callback is subclassed to the CartItemClass

		before_save :set_payment_state

		PAYMENT_STATES = {
			:waiting_to_confirm => "waiting_to_confirm"
		}

		field :payment_state, type: String, default: PAYMENT_STATES[:waiting_to_confirm]

		
		field :payment_sent, type: Boolean


		field :payment_received, type: Boolean


		#### => payment transaction id, 
		#### => a mongoid bson::object id.
		#### => this is different from transaction id, it is a unique number regenerated each time an attempt is made to pay the transaction.
		field :payment_transaction_id, type: String
	################ END PAYMENT RELATED FIELDS ############

	end


	############### START PAYMENT RELATED METHODS ##############
	
	### =>  this method should be overridden in the implementing class to decide the payment state
	### => it is called before_create and before_update
	def set_payment_state

	end

	def before_send_payment(ptid)
		payment_transaction_id = ptid
		payment_sent = nil
		payment_received = nil
		save
	end

	def after_payment_success
		payment_sent = true
		save
	end

	############### END PAYMENT RELATED METHODS ###############

	private
	def resource_id_not_changed
	  ##this method will give you access to be able to reset the resource_id in case the admin is modifying the resource.
	  ##need to check if that can be done?

	  if resource_id_changed? && resource_id_was
	      errors.add(:resource_id, "You cannot change or view this cart item")
	  end
	end

	module ClassMethods
		##used in cart controller concern.
		##you can modify this to allow admin to also view/update/etc the cart items.
		def find_cart_item(params_cart_item_id,resource)
			self.where(:_id =>params_cart_item_id, :resource_id => resource.id.to_s).first
		end

		##used in transactions controller concern.
		##and in cart item controller concern#index
		def find_cart_items(resource,parent_id=nil)
			conditions = {:resource_id => resource.id.to_s}
			if parent_id
				self.where(conditions.merge({:parent_id => parent_id}))
			else
				self.where(conditions)
			end
		end

		##only called from the transaction_controller_concern#pay method, so cart_items is already assured to exist.
		##returns the total of the prices of all the cart items
		def total(cart_items)
			cart_items.inject{|sum,n| sum + n.price}
		end

	end
	
end