##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::CartItemConcern



	extend ActiveSupport::Concern
	
	include Auth::Concerns::Shopping::ProductConcern
	include Auth::Concerns::OwnerConcern


	included do 

		

		##PERMITTED
		##the id of the product to which this cart item refers.
		##permitted
		field :product_id, type: String

		##the user id who is buying this product.
		##not permitted
		field :resource_id, type: String
		
		##PERMITTED
		##the number of this product that are being added to the cart
		##permitted
		field :quantity, type: Integer, default: 1

		##PERMITTED
		##when it is paid for, a transaction should get generated.
		##not permitted
		field :parent_id, type: String

		##PERMITTED
		##is it being discounted, can be from 0 -> 100 percent discount
		##not permitted
		field :discount, type: Float

		##PERMITTED
		##discount code to offer discounts
		##permitted
		field :discount_code, type: String


		###################### product status fields ##################
		## one of the stages mentioned below.
		field :accepted, type: Boolean


		### a percentage of the total price , at which to accept the order.
		## order accepted only if credit exceeds this number
		field :accept_order_at_credit, type: Float

	end


		
	

	module ClassMethods

		##used in cart controller concern.
		##you can modify this to allow admin to also view/update/etc the cart items.
		def find_cart_item(params_cart_item_id,resource)
			self.where(:_id =>params_cart_item_id, :resource_id => resource.id.to_s).first
		end

		##used in cart_item_controller_concern#index
		##used in cart_controller_concern#show
		def find_cart_items(resource,cart=nil)
			conditions = {:resource_id => resource.id.to_s, :parent_id => nil}
			if cart
				conditions[:parent_id] = cart.id.to_s 
			end
			self.where(conditions)
		end

	end



	## this method should be overridden in models implementing , so that you can have finegrained control over stages of the product. 
	## pass in the stage as nil, in case you want to determine it by the inherent logic presented hereunder.
	## the order is accepted if there is sufficient credit to accept it.
	## or if the credit acceptence level is acceptable.
	def set_stage(accepted,cart,resource)
		## first check the payable at.
		## then check the credit.
		## then return.
		## this again depends upon what stage you want to set.
		## if it has no stage, then the initial logic is used, otherwise then assign stage directly.
		self.accepted = accepted if accepted

	end
	
	

end