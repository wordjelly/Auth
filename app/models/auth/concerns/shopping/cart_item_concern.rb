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
		## the current item is accepted only if (price*accept_order_at_percentage_of_price) <= available credit
		field :accept_order_at_percentage_of_price, type: Float, default: 1.00

	end


	module ClassMethods

		## used in cart_item_controller_concern#show
		## if the resource is nil, will look for a cart item, which has a resource of nil, otherwise will look for a cart item, with the provided resource id.
		## 
		def find_cart_item(options)
			conditions = {:_id => options[:cart_item_id]}
			conditions[:resource_id] = options[:resource].id.to_s if options[:resource]
			puts "conditions become:"
			puts conditions.to_s
			all = self.where(conditions)
			return all.first if all.size > 0 
			return nil
		end

		##used in cart_item_controller_concern#index
		## if there is a resource, will return all cart items with that resource id.
		## if there is no resource, will return all cart items with a nil rsource.
		def find_cart_items(options)
			puts "options are: #{options.to_s}"
			conditions = {:resource_id => nil}
			conditions[:resource_id] = options[:resource].id.to_s if options[:resource]
			puts "conditions are:"
			puts conditions.to_s
			self.where(conditions)
		end

	end

	## decides whether or not the current item can be accepted , given whatever money has been paid by the resource.
	## will first set the order as accepted, provided that the cart has enough credit. While checking for the credit, will debit the minimum amount necessary to accept this cart item, from the cart credit.
	## in the next line, whatever is set using the first line, can be directly overridden setting the override value to true|false.
	## returns the result of calling #save on the cart_item.
	def set_accepted(cart,resource,override)
		self.accepted = cart_has_sufficient_credit_for_item?(cart,resource) 
		self.accepted = override if override
		self.save
		self
	end
	
	## debits an amount from the cart equal to (item_price*accept_order_at_percentage_of_price)
	## the #debit function returns the current cart credit.
	## return true or false depending on whether , after debiting there is any credit left in the cart or not.
	def cart_has_sufficient_credit_for_item?(cart,resource)
		
		cart.debit((self.accept_order_at_percentage_of_price*self.price), resource) >= 0
	end

end