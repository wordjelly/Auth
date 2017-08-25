##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::PaymentConcern

	extend ActiveSupport::Concern
	
	included do 

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

		##NOT PERMITTED , ONLY FOR INTERNAL ASSIGNMENT.
		field :payment_state, type: String, default: PAYMENT_STATES[:waiting_to_confirm]

			
		##NOT PERMITTED, ONLY FOR INTERNAL ASSIGNMENT
		field :payment_sent, type: Boolean

		##NOT PERMITTED, ONLY FOR INTERNAL ASSIGNMENT
		field :payment_received, type: Boolean

		##not permitted, only for internal assignment.
		#### => payment transaction id, 
		#### => a mongoid bson::object id.
		#### => this is different from transaction id, it is a unique number regenerated each time an attempt is made to pay the transaction.
		field :payment_transaction_id, type: String


		##PERMITTED.
		## => PAYMENT TYPE
		## => string can be "cash,cheque,card"
		field :payment_type, type: String

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

end
