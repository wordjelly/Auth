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


		################### which payment led to this cart item being accepted

		field :accepted_by_payment_id, type: String

		### a percentage of the total price , at which to accept the order.
		## the current item is accepted only if (price*accept_order_at_percentage_of_price) <= available credit
		field :accept_order_at_percentage_of_price, type: Float, default: 1.00


		before_destroy do |document|
			false if document.accepted == true
		end

		after_validation do |document|
			document.refresh_accepted
		end

		validate :user_can_only_update_quantity_and_discount_code

		validate :user_cannot_change_anything_if_payment_accepted



	end


	module ClassMethods

		## used in cart_item_controller_concern#show
		## if the resource is nil, will look for a cart item, which has a resource of nil, otherwise will look for a cart item, with the provided resource id.
		## 
		def find_cart_item(options)
			conditions = {:_id => options[:cart_item_id]}
			conditions[:resource_id] = options[:resource].id.to_s if options[:resource]
			all = self.where(conditions)
			return all.first if all.size > 0 
			return nil
		end

		##used in cart_item_controller_concern#index
		## if there is a resource, will return all cart items with that resource id.
		## if there is no resource, will return all cart items with a nil rsource.
		def find_cart_items(options)
			conditions = {:resource_id => nil, :parent_id => nil}
			conditions[:resource_id] = options[:resource].id.to_s if options[:resource]
			self.where(conditions)
		end

	end

	### this is an internal method, cannot be set by admin or anyone, it is done after validation, since it is not necessary for someone to be admin, even the user can call refresh on the record to get the new state of the acceptence.
	## just checks if the accepted by payment id exists, and if yes, then doesnt do anything, otherwise will update the cart item status as false.
	def refresh_accepted
		if self.accepted_by_payment_id
			begin
				Auth.configuration.payment_class.constantize.find(self.accepted_by_payment_id)
			rescue
				self.accepted = false
			end
		end
	end
	
	## called from payment#update_cart_items_accepted
	## sets accepted to true or false depending on whether the cart has enough credit for the item.
	## does not SAVE.
	def set_accepted(payment,override)
		#return cart_has_sufficient_credit_for_item?(payment.cart)
		if cart_has_sufficient_credit_for_item?(payment.cart) 
			## is it already accepted?
			if self.accepted
				return true
			else
				self.accepted = true
			end
		else
			self.accepted = false
		end
		self.accepted = override if override
		self.accepted_by_payment_id = payment.id.to_s if self.accepted == true
		self.save

	end
	
	## debits an amount from the cart equal to (item_price*accept_order_at_percentage_of_price)
	## the #debit function returns the current cart credit.
	## return true or false depending on whether , after debiting there is any credit left in the cart or not.
	def cart_has_sufficient_credit_for_item?(cart)
		
		cart.debit((self.accept_order_at_percentage_of_price*self.price)) >= 0
	end

	## will unset the cart if this method returns true.
	## otherwise will not unset the cart.
	## override to change the behaviour.
	def before_unset_cart
		true
	end

	## called if self.parent_id remains nil, after calling unset_cart
	## called in unset_cart
	def on_unset_failed

	end



	def on_unset_success

	end

	## unsets the parent id from this cart item. i.e removes the cart item from the cart.
	## calls the before_unset as a block => that's where you have to add your code to decide whether to allow the parent_id to be set as nil or not.
	## @used_in : cart_controller_concern # add_or_remove
	## @return[Boolean] : result of saving the cart item.
	def unset_cart
		if before_unset_cart == true
			self.parent_id = nil
			self.save
		end
		self.parent_id.nil? ? on_unset_success : on_unset_failed
	end


	## assigns a cart and resource, resource_id to the cart_item.
	## @returns : true or false depending on whether the cart item was successfully saved or not.
	## @used_in : cart_controller_concern # add_or_remove
	def set_cart_and_resource(cart)
		self.parent_id = cart.id.to_s
		self.resource_class = cart.get_resource.class.name
		self.resource_id = cart.get_resource.id.to_s
		self.save
	end

	#######################################################
	##
	## VALIDATIONS
	##
	#######################################################

	def user_can_only_update_quantity_and_discount_code
		if !self.signed_in_resource.is_admin? && !self.new_record?
			self_keys = self.attributes.keys
			self_keys.each do |k|
				if k == "discount" 
				elsif k == "quantity"
				else
					self.send("#{k}=",self.send("#{k}_was"))
				end
			end
			
		end
	end

	def user_cannot_change_anything_if_payment_accepted
		if !self.signed_in_resource.is_admin?
			self.errors.add(:quantity,"you cannot change this item since payment has already been made") if self.accepted_by_payment_id && self.changed? && !self.new_record?
		end
	end

end