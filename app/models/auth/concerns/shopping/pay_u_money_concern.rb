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

		## gateway_payment_request
		## when a request is initialized by the user to make the gateway payment, it first updates the payment object with this url, and then redirects to the url.
		## this also simplifies checking payment_verification as verification is only intiaated for those payments which have this url, but do not ave 
		field :gateway_payment_initiated, type: String



		##remember to set the default_url_options in the dummy app routes file.
		before_create do |document|
			if document.is_gateway?
				document.gateway_payment_initiated = true 
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

	

	## Interpretation: 
	## check validation errors, if none, then there should be a payment status.
	def verify_payment
		if self.gateway_payment_initiated
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
								if details["transaction_details"]["status"]
									self.payment_status = 1 if details["transaction_details"]["status"].to_s.downcase == "success" 
									self.payment_status = 0 if details["transaction_details"]["status"].to_s.downcase =~/pending|failed/
									if payment_status_changed?
										self.save
									else
										self.errors.add(:payment_status,"transaction status was something other than failed|success|pending")
									end

								else
									self.errors.add(:payment_status,"transaction details has no status key in it.")
									
								end
							else
								self.errors.add(:payment_status,"transaction details key missing from response")
								
							end
						else
							self.errors.add(:payment_status,"status key is neither 1 not 0")
							
						end
						
					else
						self.errors.add(:payment_status,"no status key in payment verification response")
						
					end

				rescue => e
					Rails.logger.error(e.to_s)
					self.errors.add(:payment_status,"failure parsing payment response")
				end
			else
				## does nothing, the caller has to check the payment_status to infer that the call was not successfull.
				self.errors.add(:payment_status,"no response from verify endpoint")
			end
		else
			self.errors.add(:payment_status,"payment was never initiated")
		end
	end


	def payment_gateway_key
		Auth.configuration.payment_gateway_info[:key]
	end


	def payment_gateway_salt
		Auth.configuration.payment_gateway_info[:salt]
	end


	 ##this method is overriden here from the payment_concern.
	 def gateway_callback(pr,&block)
	 	return if self.new_record?
	  	notification = PayuIndia::Notification.new("", options = {:key => Auth.configuration.payment_gateway_info[:key], :salt => Auth.configuration.payment_gateway_info[:salt], :params => pr})
	  	self.payment_status = 0
	  	self.payment_status = 1 if(notification.acknowledge && notification.complete?)
	  	yield if block_given?
	 end

end