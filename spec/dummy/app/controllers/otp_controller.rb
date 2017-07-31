class OtpController < Auth::ApplicationController

	
	
	  ##actions before each request
	  ##permitted_params.deep_symbolize
	  ##set response status
	  ##set intent

	  before_filter :initialize_vars

	  def initialize_vars
	  	##deep symbolize the incoming params after passing through permitted params.
	  	@resource_params = permitted_params.deep_symbolize_keys
	  	puts @resource_params.to_s
	  	##if the resource is defined, assign the class and the symbol for use further in the file
	  	##eg: resource is provided in the route as : users, so 
	  	##@resource_class => User
	  	##@resource_symbol =>  :user
	  	if collection = @resource_params[:resource]
	  		##check that the resource exists in the auth_configuration
	  		if Auth.configuration.auth_resources[collection.singularize.capitalize]
	  			@resource_class = collection.singularize.capitalize.constantize
	  			@resource_symbol = collection.singularize.to_sym
	  					
	  			puts "resource class is:"
	  			puts @resource_class

	  			puts "resource sybmol is:"
	  			puts @resource_symbol
	  			##this is either the provided email(in case of forgot_password form, we pass in the additional_login_param under the email key itself.#ref auth/modals/forgot_password_content.html.erb)
	  			if @resource_params[@resource_symbol]
				  	@additional_login_param = @resource_params[@resource_symbol][:email] || @resource_params[@resource_symbol][:additional_login_param]

				  	##the otp provided by the user, only used in the verify_otp action.
				  	@otp = @resource_params[@resource_symbol][:otp]
				  	
				  	##the resource_id of the user, only used in the short_polling endpoint.
				  	@resource_id = @resource_params[@resource_symbol][:_id]
	  			end

	  		else
	  			not_found
	  		end
	  	else
	  		not_found
	  	end
	  	
	  	##the intent , passed into the send_sms_otp endpoint, and thereafter added to the verify_otp_path, in the new_otp_input.html.erb
	  	@intent = @resource_params[:intent] or ""
	  	puts "intent is : #{@intent}"

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
	  	
	  	if resource = @resource_class.where(conditions).first
	  		resource.send_sms_otp
	  	elsif resource = @resource_class.new
	  		@status = 422
	  		resource.errors.add(:email,"Not found")
	  		resource.errors.add(:additional_login_param,"Not found")
	  	end 
	  	respond_to do |format|
  		  format.json {render json: resource.to_json, status: @status}
  		  format.js   {render :partial => "auth/confirmations/new_otp_input.js.erb", locals: {resource: resource, intent: @intent}}
  		end
	  end


	  ##CALLED WHEN WE WANT TO SHOW THE USER A MODAL TO RE-ENTER HIS MOBILE NUMBER SO THAT WE CAN AGAIN SEND AN OTP TO IT.
	  ##so what happens after resend?
	  def resend_sms_otp
	  	if resource = @resource_class.new
	  	else
	  		@status = 400
	  	end
	  	respond_to do |format|
  		  format.json {render json: resource.to_json, status: @status}
  		  format.js   {render "auth/confirmations/_resend_otp.js.erb", locals: {resource: resource, intent: @intent}}
  		end
	  end

	  ##CALLED WHEN THE USER ENTERS THE OTP SENT ON HIS MOBILE
	  ##VERIFIES THE OTP WITH THE THIRD PARTY API.
	  def verify_otp
	  	if resource = @resource_class.where(:additional_login_param => @additional_login_param).first 
	  		resource.otp = @otp
	  		##there are no errors, so we proceed with verification.
	  		if otp_error = resource.check_otp_errors
	  			@status = 422
	  			resource.errors.add(:email,otp_error)
	  			resource.errors.add(:additional_login_param,otp_error)
	  		else
	  			resource.verify_sms_otp
	  		end
	  	else
	  		@status = 400
	  	end
	  	respond_to do |format|
  		  format.json {render json: resource.to_json, status: @status}
  		  format.js   {render :partial => "auth/confirmations/verify_otp.js.erb", locals: {resource: resource, intent: @intent, otp: @otp}}
  		end
	  end


	  ##SHORT-POLLING ENDPOINT TO DETERMINE IF THE OTP WAS VALID.
	  ##CALLED IN THE POST-VERIFICATION PAGE.
	  def otp_verification_result
	  	intent_url = nil
	  	res_verified = false
	  	##first check the errors
	  		
	  	if @resource_id && resource = @resource_class.where(:_id => @resource_id, :otp => @otp).first
	  		
	  		if otp_error = resource.check_otp_errors
	  			@status = 422
		  		resource.errors.add(:additional_login_param,otp_error)
	  		else

	  			res_verified = resource.additional_login_param_status == 2
	  		
			  	if res_verified && @intent
				  	if @intent == "reset_password"
				  		##protected method so had to do this.
				  		raw_token = resource.send(:set_reset_password_token)
				  		intent_url = send("edit_#{@resource_symbol.to_s}_password_path",{:reset_password_token => raw_token})
				  	elsif @intent == "unlock_account"
				  		##here normally would be resource.unlock.
				  		##code from https://github.com/plataformatec/devise/blob/master/lib/devise/models/lockable.rb#send_unlock_instructions
				  		puts "came to unlocks."
				  		raw, enc = Devise.token_generator.generate(resource.class, :unlock_token)
	        			resource.unlock_token = enc
	        			resource.save(validate: false)
	        			intent_url = send("#{@resource_symbol.to_s}_unlock_path",{:unlock_token => raw})
				  	end
			  	end
			end
		else
			resource = @resource_class.new
			@status = 422
			resource.errors.add(:additional_login_param,"resource not found")
		end

	  	respond_to do |format|
	  		format.json {render json: {:follow_url => intent_url, :verified => res_verified, :errors => resource.errors.full_messages}, status: @status}
	  	end

	  end

	  def permitted_params
	  	if action_name == "resend_sms_otp"
	  		##the resource_collection_path => pluralized downcased model name eg. users
	  		params.permit(:resource, :intent)
	  	else
	  		##post_verification_intent => "reset_password" OR "unlock"
	  		##had to add email here because in the passwords form, and the unlocks form, we have to serve either additional_login_param or email, so in order to make it work with the existing devise controllers decided to keep the param coming in as email, and sending errors back also on the email attribute,[all this is only relevant to the send_sms_otp action]
	  		params.permit({user: [:additional_login_param, :otp, :email, :_id]}, :intent, :resource)
	  	end
	  end	

end