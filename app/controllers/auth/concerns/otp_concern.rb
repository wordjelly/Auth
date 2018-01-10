module Auth::Concerns::OtpConcern
	extend ActiveSupport::Concern

	included do 
		include Auth::Concerns::DeviseConcern
	    ##refer to auth/applicationcontroller for the not_found def, and its rescue block.
	    before_filter :do_before_request
	    before_filter :initialize_vars
	    before_filter :check_recaptcha, only: [:send_sms_otp,:verify_otp]
	    
	end

	def initialize_vars
	  	##deep symbolize the incoming params after passing through permitted params.
	  	
	  	@resource_params = permitted_params.deep_symbolize_keys
	  	
	  	##if the resource is defined, assign the class and the symbol for use further in the file
	  	##eg: resource is provided in the route as : users, so 
	  	##@resource_class => User
	  	##@resource_symbol =>  :user

	  	if collection = @resource_params[:resource]
	  		##check that the resource exists in the auth_configuration
	  		if Auth.configuration.auth_resources[collection.singularize.capitalize]
	  			@resource_class = collection.singularize.capitalize.constantize
	  			@resource_symbol = collection.singularize.to_sym
	  					
	  			#puts "resource class is:"
	  			#puts @resource_class

	  			#puts "resource sybmol is:"
	  			#puts @resource_symbol
	  			##this is either the provided email(in case of forgot_password form, we pass in the additional_login_param under the email key itself.#ref auth/modals/forgot_password_content.html.erb)
	  			if @resource_params[@resource_symbol]
				  	@additional_login_param = @resource_params[@resource_symbol][:email] || @resource_params[@resource_symbol][:additional_login_param]
				  	
				  	

				  	##the otp provided by the user, only used in the verify_otp action.
				  	@otp = @resource_params[@resource_symbol][:otp]
				  	
				  	##the resource_id of the user, only used in the short_polling endpoint.
				  	@resource_id = @resource_params[@resource_symbol][:_id]
				  	
	  			end

	  		else
	  			##have to have some way of showing these errors.
	  			not_found("provided resource not found in app")
	  		end
	  	else
	  		not_found("no resource collection provided")
	  	end
	  	
	  	##the intent , passed into the send_sms_otp endpoint, and thereafter added to the verify_otp_path, in the new_otp_input.html.erb
	  	##set as default to empty so that it doesnt screw up in the partials, screaming undefined.
	  	@intent = @resource_params[:intent] or ""
	  	
	  	
	  	##the default response status, can be changed in the action depending on individual situations.
	  	@response_status = 200
	end

  	##CALLED WHEN THE USER HAS ENTERED HIS MOBILE NUMBER, SO THAT HE GETS ANOTHER OTP
  	def send_sms_otp
	  	##IF THERE IS AN INTENT,THEN WE MUST HAVE A CONFIRMED ACCOUNT.
	  	##OTHERWISE WE DONT NEED THAT.
	  	##WHY?
	  	##because : suppose that we are calling send_sms_otp from the forgot_password / unlocks controller -> then we have to ensure that the account has been verified.
	  	##otherwise we cannot send otp's to non-verified phone numbers to do things like reset_passwords / unlock 
	  	##on the other hand in case there is no intent, like in case of resend_otp -> then we can only check if we have an account with this mobile number or not, no need to check for verification.
	  	conditions = @intent.blank? ? {:additional_login_param => @additional_login_param} : {:additional_login_param => @additional_login_param, :additional_login_param_status => 2}
	  
	  	if @additional_login_param.nil?
	  		@status = 422
	  		resource = @resource_class.new
	  		resource.errors.add(:additional_login_param,"Additional login param not provided")
	  	elsif resource = @resource_class.where(conditions).first
	  		#resource.intent_token = Devise.friendly_token if !@intent.blank?
	  		#resource.save
	  		resource.m_client = self.m_client
	 		resource.set_client_authentication
	  		resource.send_sms_otp
	  	elsif resource = @resource_class.new
	  		@status = 422
	  		resource.errors.add(:additional_login_param,"Could not find a resource with that additional login param")
	  	end 
	  	respond_to do |format|
			  format.json {render json: resource.to_json({:otp_verification => true}), status: @status}
			  format.js   {render :partial => "auth/confirmations/new_otp_input.js.erb", locals: {resource: resource, intent: @intent}}
		end
  	end


  	##CALLED WHEN WE WANT TO SHOW THE USER A MODAL TO RE-ENTER HIS MOBILE NUMBER SO THAT WE CAN AGAIN SEND AN OTP TO IT.
  	def resend_sms_otp
  		resource = @resource_class.new
  		respond_to do |format|
		  format.json {render json: resource.to_json, status: @status}
		  format.js   {render "auth/confirmations/_resend_otp.js.erb", locals: {resource: resource, intent: @intent}}
		end
  	end

	##CALLED WHEN THE USER ENTERS THE OTP SENT ON HIS MOBILE
	##VERIFIES THE OTP WITH THE THIRD PARTY API.
	def verify_otp
	  	if resource = @resource_class.where(:additional_login_param => @additional_login_param).first 
	  		resource.m_client = self.m_client
	 		resource.set_client_authentication
	  		##there are no errors, so we proceed with verification.
	  		if otp_error = resource.check_otp_errors
	  			@status = 422
	  			resource.errors.add(:additional_login_param,otp_error)
	  		else
	  			resource.verify_sms_otp(@otp)
	  		end
	  	else
	  		resource = @resource_class.new
	  		resource.errors.add(:additional_login_param,"Not Found")
	  		@status = 400
	  	end
	  	respond_to do |format|
  		  format.json {render json: resource.as_json({:otp_verification => true}), status: @status}
  		  format.js   {render :partial => "auth/confirmations/verify_otp.js.erb", locals: {resource: resource, intent: @intent, otp: @otp}}
  		end
	end


  	##SHORT-POLLING ENDPOINT TO DETERMINE IF THE OTP WAS VALID.
  	##CALLED IN THE POST-VERIFICATION PAGE.
  	##error returns for this def are different, because it is requested using json from the verify_otp.js.erb partial
  	##as a result, in case there is an error in the controller action itslef below(eg. wherever there is a 422/400), then the following happens.
  	##spinner.js
  	##//catches any non 200/201 status and interprets it as an error
  	##//thereafter directly show_error_modal is called.
  	##//i could have written logic specific for otp_verification_result, by checking if it is there in the request_url, but did not do so, because otp is not always going to be in the engine, so otp should not be hardcoded anywhere.
  	##//the error lands up being shown inside show_error_modal, by means of json parsing the incoming string, and showing json[:errors] as the error message.
  	##on the other hand, if there is any othe rtype of error in the before_filter initialize_vars, then that raises a not_found and is handled by rendering a json response with errors, and a 422 so again it is handled by spinner as above.
  	def otp_verification_result
	  	intent_url = nil
	  	res_verified = false
	  	##first check the errors
	  	

	  	if @resource = @resource_class.where(:additional_login_param => @additional_login_param, :otp => @otp).first
	  		
	  		if otp_error = @resource.check_otp_errors
	  			@status = 422
		  		@resource.errors.add(:additional_login_param,otp_error)
	  		else
	  			@resource.m_client = self.m_client
	 			@resource.set_client_authentication	
			  	if @resource.additional_login_param_confirmed? 
				  	if @intent == "reset_password"
				  		puts "came to intent with reset password."
				  		##protected method so had to do this.
				  		if @resource.confirmed? && !@resource.	pending_reconfirmation?
				  			@resource.class.send_reset_password_instructions(@resource.attributes)
				  			puts "should have sent the email now."
				  			##if successfull_sent ->
				  			##else
				  			## here error is added anyway to resource.
				  			##end
				  			##we want to send the reset password instructions, but using the email.
				  		else
				  			puts "should have encountered and error."
				  			@resource.errors.add(:additional_login_param,"you do not have a confirmed email account set for this account, you cannot recover the password.")
				  			puts @resource.errors.full_messages.to_s
				  			@status = 400
				  		end
				  		#raw_token = resource.send(:set_reset_password_token)
				  		#intent_url = send("edit_#{@resource_symbol.to_s}_password_path",{:reset_password_token => raw_token})
				  	elsif @intent == "unlock_account"
				  		##here normally would be resource.unlock.
				  		##code from https://github.com/plataformatec/devise/blob/master/lib/devise/models/lockable.rb#send_unlock_instructions
				  		#puts "came to unlocks."
				  		raw, enc = Devise.token_generator.generate(@resource.class, :unlock_token)
	        			@resource.unlock_token = enc
	        			@resource.save(validate: false)
	        			intent_url = send("#{@resource_symbol.to_s}_unlock_path",{:unlock_token => raw})
				  	end
				  	##make the intent token nil, it can be used only thus once.
				  	
			  	end
			end
		else
			@resource = @resource_class.new
			@status = 422
			@resource.errors.add(:additional_login_param,"Either otp or additional login param is incorrect, try resend otp")
		end

	  	respond_to do |format|
	  	  format.json {render json: {:follow_url => intent_url, :errors => @resource.errors.full_messages, :resource => @resource.as_json({:otp_verification => true}), :verified => (@resource.additional_login_param_confirmed? && @resource.errors.empty?)}, status: @status}
	  	end
 	end



	def permitted_params
	  	if action_name == "resend_sms_otp"
	  		##the resource_collection_path => pluralized downcased model name eg. users
	  		params.permit(:intent,:resource,:api_key,:current_app_id)
	  	else
	  		##post_verification_intent => "reset_password" OR "unlock"
	  		##had to add email here because in the passwords form, and the unlocks form, we have to serve either additional_login_param or email, so in order to make it work with the existing devise controllers decided to keep the param coming in as email, and sending errors back also on the email attribute,[all this is only relevant to the send_sms_otp action]
	  		##it will take all the models provided in the authentication_keys in the Auth configuration file.
	  		filters = []
	  		Auth.configuration.auth_resources.keys.each do |model|
	  			filters << {model.downcase.to_sym => [:additional_login_param, :otp, :email, :_id]}
	  		end
	  		filters << [:intent, :resource,:api_key,:current_app_id]
	  		params.permit(filters)
	  	end
	end	


end