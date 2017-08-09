##need a seperate model that implements it.
module Auth::Concerns::Shopping::TransactionConcern

	extend ActiveSupport::Concern

	include Mongoid::TimeStamps

	included do 
		##before_create do |document|
			##set and save all the individual cart_items that currently don't have a transaction id.
				##server shut down -> 
			##gather the responses, are all valid.
			##otherwise abort and fail.
			##so in that case, it will try again.
			##but this time, it will have only half the cart_items as not having a transaction id.
			##the earlier failed cart items will be lost completely.
			##so we shift it to after_create
			##what happens after create
			##suppose that some get id, then the others which don't get it
			##will be without an id.
			##how will we know that it failed.
			##while displaying the transaction
			##that can be sent in the response
			##but then what is to be done?
			##the remaining items can be readded as updates one at a time.
			##in the meantime, if the cart is to be viewed, we will have to add a query, that it is not present in any transaction id models.
			##not necessary while creating a transaction, it should be checked that each item is not part of any other transaction.
			##but while showing in the cart then how to do it without two queries.
		##end

		##before_update do |document|
			##you can only add one cart item at a time to a document.
			##so that will be transactional.
			##suppose we want to remove
			##we can remove multiple, but does that shift them from the 
			##transaction back to the cart
			##no it destroy's them completely.
			##so unless all are destroyed, we don't do the update.
		##end

		##

		##the cart items added to this transaction.
		field :cart_item_ids, type: Array
		##when the person wants to pay
		##on delivery of results
		##on order
		##on completion of results, but before delivery
		field :preferred_payment_stage, type: String, default: "on_order"
		##modified internally through callbacks.
		##all the payments made into and out of this transaction.
		##this is a list of history object ids.
		##each history object contains the history of this transaction.
		field :history, type: Array
		##this is also set internally through callbacks.
		##status of payment : payed / not paid
		field :payment_status, type: String, default: "not_paid"
		##this is set internally through callbacks.
		##status of transaction : ordered / pending.
		field :transaction_status, type: String , default: "pending"
	end




end