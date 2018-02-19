module Auth::Concerns::Shopping::PayUMoneyConcern

	extend ActiveSupport::Concern
	
	include Auth::Concerns::ChiefModelConcern	

	included do 
		field :firstname, type: String
		field :email, type: String
		field :phone, type: String
		##same as the payment id.
		field :txnid, type: String
		field :surl, type: String
		field :furl, type: String
		##same as the cart name
		field :productinfo, type: String
		##amount is not added here, because it is already a part of the payment_concern
		##the hash calculated by using the payumoney library.
		field :hast, type: String

		



		##remember to set the default_url_options in the dummy app routes file.
		before_create do |document|
			if document.is_gateway?
				
				document.surl = document.furl = Rails.application.routes.url_helpers.shopping_payment_url(document.id.to_s)
				document.txnid = document.id.to_s
				#document.txnid = "a#{Random.new.rand(1..50)}"
				document.calculate_hash 
			end
		end

		
		##add a validation, that checks that each of the 7 required fields are present, before create, only when the payment_type is gateway.
		##the is_gateway? method is defined in payment_concern.
		##these validations are run before the before_save is called.
		##so will throw an error if either of the following are not present.
		validates_presence_of   :firstname, if: :is_gateway?
		validates_presence_of   :email, if: :is_gateway?
		validates_presence_of   :phone, if: :is_gateway?
		validates_presence_of 	:productinfo, if: :is_gateway?

	end

	##needs to use the payumoney library.
	def calculate_hash
		options = {:firstname => firstname, :email => email, :phone => phone, :txnid => txnid, :surl => surl, :furl => furl, :productinfo => productinfo, :amount => amount}
		service = PayuIndia::Helper.new(payment_gateway_key, payment_gateway_salt, options)
		self.hast = service.generate_checksum
	end

	

	
	def verify_payment
		
		if self.new_record?
		
			return nil
		else
		
			if self.is_verify_payment == "true"
				#puts "yes is verify payment."
				#puts the payment is not getting set as pending.
				## that is the problem.
				if self.payment_pending
						
					if self.is_gateway?
					 	#puts "came to is gateway"
						options = {:var1 => self.txnid, :command => 'verify_payment'}
						webservice = PayuIndia::WebService.new(payment_gateway_key,payment_gateway_salt,options)
						sha_hash = webservice.generate_checksum
							if resp = Typhoeus.post(PayuIndia.webservice_url, body: 
								{ key: payment_gateway_key, command: 'verify_payment', hash: sha_hash, var1: self.txnid}, headers: {'Content-Type' => 'application/x-www-form-urlencoded'})
								Rails.logger.info(resp.body + ":transaction_id:" + self.id.to_s)
								begin
									details = JSON.parse(resp.body)

									if status = details["status"].to_s		
										self.payment_status = 0 if (status == "0")
											
										if status == "1"
											if details["transaction_details"]
												if transaction_details = 
												details["transaction_details"][txnid.to_s]

													if transaction_details["status"]
													
														self.payment_status = 1 if transaction_details["status"].to_s.downcase == "success" 
														self.payment_status = 0 if transaction_details["status"].to_s.downcase =~/pending|failure/
														if payment_status_changed?
															## prevents recursive callbacks, after save.
															self.is_verify_payment = "false"
															self.save
														else
															self.errors.add(:payment_status,"transaction status was something other than failed|success|pending")
														end
													else
														self.errors.add(:payment_status,"transaction details does not have the status key. Please try to verify your payment later, or contact Support for more help.")
													end
												else
													self.errors.add(:payment_status,"transaction details does not have the transaction id. Please try to verify your payment later, or contact Support for more help.")
													
												end
											else
												self.errors.add(:payment_status,"transaction details key missing from response")
												
											end
										else
											self.errors.add(:payment_status,"status key is neither 1 not 0 : Please try to verify your payment later, or contact Support for more help.")
											
										end
										
									else
										self.errors.add(:payment_status,"no status key in payment verification response. Please try to verify your payment later, or contact Support for more help.")
										
									end

								rescue => e
									Rails.logger.error(e.to_s)
									self.errors.add(:payment_status,"failure parsing payment response. Please try to verify your payment later, or contact Support for more help.")
								end
							else
								## does nothing, the caller has to check the payment_status to infer that the call was not successfull.
								self.errors.add(:payment_status,"no response from verify endpoint. Please try to verify your payment later, or contact Support for more help.")
							end
					
						end

					return true
				else

					puts "not pending"
					return nil
				end
			else
				puts "is not verify payment."
				return nil
			end
		end
		
	end


	def payment_gateway_key
		Auth.configuration.payment_gateway_info[:key]
	end


	def payment_gateway_salt
		Auth.configuration.payment_gateway_info[:salt]
	end


	 ##this method is overriden here from the payment_concern.
	 ##suppose the user is calling refresh_payment, basically an update call, then the mihpayid wont be present so the gateway callback becomes pointless.
	 ## and then we just let verify payment handle the situation.
	 def gateway_callback(pr,&block)
	 	

	 	return if (self.new_record? || self.is_verify_payment == "true")
	 	
=begin
	  	notification = PayuIndia::Notification.new("", options = {:key => Auth.configuration.payment_gateway_info[:key], :salt => Auth.configuration.payment_gateway_info[:salt], :params => pr})
	  	self.payment_status = 0
	  	if(notification.acknowledge && notification.complete?)
	  		self.payment_status = 1 
	  	end
=end

		## we should just set, gateway callback complete as true, and based on that never show the pay with payumoney link again in the show action.

		## just looking to see if  
		if (pr["mihpayid"] && pr["hash"] && (pr["txnid"] == self.id.to_s))
			self.gateway_callback_called = true
		end
	  	yield if block_given?
	  	return true
	 end

end