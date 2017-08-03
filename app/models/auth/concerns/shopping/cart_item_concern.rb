##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::CartItemConcern

	extend ActiveSupport::Concern

	include Auth::Concerns::ProductConcern
	include Mongoid::TimeStamps

	included do 

		##the id of the product to which this cart item refers.
		field :product_id, type: BSON::ObjectId

		##the user id who is buying this product.
		field :user_id, type: BSON::ObjectId
			
		##the number of this product that are being added to the cart
		field :quantity, type: Integer, default: 1

		##when it is paid for, a transaction should get generated.
		field :transaction_id, type: String

		##is it being discounted, can be from 0 -> 100 percent discount
		field :discount, type: Float


	end

end