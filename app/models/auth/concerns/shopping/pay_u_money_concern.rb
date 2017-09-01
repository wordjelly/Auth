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

	## makes an api call to the payumoney server to verify the current payment.
	def verify_payment
		options = {:var1 => txnid, :command => 'verify_payment'}
		webservice = PayuIndia::WebService.new(payment_gateway_key,payment_gateway_salt,options)
		sha_hash = webservice.generate_checksum
		resp = Typhoeus.post(PayuIndia.webservice_url, body: 
			{ key: payment_gateway_key, command: 'verify_payment', hash: sha_hash})
		puts "made request to verify payment."
		puts resp.body.to_s
	end


	def payment_gateway_key
		Auth.configuration.payment_gateway_info[:key]
	end


	def payment_gateway_salt
		Auth.configuration.payment_gateway_info[:salt]
	end


	 ##this method is overriden here from the payment_concern.
	 def gateway_callback(pr)
	 	puts "came to gateway callback with permitted params payment as"
	 	puts JSON.pretty_generate(pr)
	 	self.gateway_payment_request_url ||= 
	  	notification = PayuIndia::Notification.new("", options = {:key => Auth.configuration.payment_gateway_info[:key], :salt => Auth.configuration.payment_gateway_info[:salt], :params => pr})
	  	self.payment_status = 0
	  	self.payment_status = 1 if(notification.acknowledge && notification.complete?)
	  	puts "notification acknowledge becomes: #{notification.acknowledge}"
	  	puts "notification complete becomes: #{notification.complete?}"
	  	puts "status becomes: #{payment_status}"
	 end

end