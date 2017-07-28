class OtpController < Auth::ApplicationController

	include Auth::Concerns::ControllerSmsOtpConcern
	

	  respond_to :html,:js,:json

	  ##CALLED WHEN THE USER HAS ENTERED HIS MOBILE NUMBER, SO THAT HE GETS ANOTHER OTP
	  def send_sms_otp
	  	resource_params = permitted_params
	  	status = 200
	  	
	  	if resource = User.where(:additional_login_param => resource_params[:email]).first
	  		##it shouldn't deconfirm in this case.
	  		resource.send_sms_otp
	  	elsif resource = User.new
	  		
	  		status = 400
	  		resource.errors.add(:email,"Not found")
	  	end 
	  	
	  	puts resource.attributes.to_s

	  	respond_to do |format|
  		  format.json {render json: {}, status: status}
  		  format.js   {render "auth/confirmations/_new_otp_input.js.erb", locals: {resource: resource}}
  		end
	  end


	  ##CALLED WHEN WE WANT TO SHOW THE USER A MODAL TO RE-ENTER HIS MOBILE NUMBER SO THAT WE CAN AGAIN SEND AN OTP TO IT.
	  def resend_sms_otp
	  	if resource_collection_path = permitted_params[:resource_collection_path]
	  		resource_pluralized = nil
	  		resource_collection_path.scan(/\/(?<resource_pluralized>[a-z]+)/) do |n|
	  			jj = Regexp.last_match
	  			resource_pluralized = jj[:resource_pluralized]
	  		end
	  		resource = Object.const_get(resource_pluralized.singularize.capitalize).new
	  	else
	  		not_found
	  	end
	  	respond_to do |format|
  		  format.json {head :ok }
  		  format.js   {render "auth/confirmations/_resend_otp.js.erb", locals: {resource: resource}}
  		end

	  end

	  ##CALLED WHEN THE USER ENTERS THE OTP SENT ON HIS MOBILE
	  ##VERIFIES THE OTP WITH THE THIRD PARTY API.
	  def verify_otp
	  	resource_params = permitted_params
	  	if resource = User.where(:additional_login_param => resource_params[:additional_login_param], :additional_login_param_status => 1).first 
	  		resource.verify_sms_otp(resource_params[:otp])
	  		##after verify, a password reset token can be set.
	  		##then if the otp is verified, it can redirect
	  		##to  
	  	else
	  		not_found
	  	end
	  	respond_to do |format|
  		  format.json { head :ok }
  		  format.js   {render "auth/confirmations/_verify_otp.js.erb", locals: {resource: resource}}
  		end
	  end


	  ##SHORT-POLLING ENDPOINT TO DETERMINE IF THE OTP WAS VALID.
	  ##CALLED IN THE POST-VERIFICATION PAGE.
	  def otp_verification_result
	  	resource = User.find(params[:resource_id]) or not_found
	  	res_verified = resource.additional_login_param_status == 2 && resource.additional_login_param_per_request_status == 2
	  	post_verification_intent = params[:post_verification_intent]
	  	follow_url = nil
	  	if res_verified
		  	if post_verification_intent == "reset_password"
		  		##if verified, then set the password token.
		  		##and then redirect to the requisite path.
		  		##redirect to that path using format.rules
		  		resource.set_reset_password_token
		  		follow_url = edit_password_path(:user,resource.reset_password_token)
		  	elsif post_verification_intent == "unlock"
		  		##here normally would be resource.unlock.
		  	end
	  	end
	  	respond_to do |format|
	  		format.json {render json: {:follow_url => follow_url, :verified => res_verified}}
	  	end
	  end


	 


	  def permitted_params
	  	if action_name == "resend_sms_otp"
	  		##the resource_collection_path => pluralized downcased model name eg. users
	  		params.permit(:resource_collection_path)
	  	else
	  		##post_verification_intent => "reset_password" OR "unlock"
	  		##had to add email here because in the passwords form, and the unlocks form, we have to serve either additional_login_param or email, so in order to make it work with the existing devise controllers decided to keep the param coming in as email, and sending errors back also on the email attribute,[all this is only relevant to the send_sms_otp action]
	  		params.permit({user: [:additional_login_param, :otp, :email]}, :post_verification_intent)
	  	end
	  end	

end