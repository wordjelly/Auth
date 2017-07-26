class OtpController < Auth::ApplicationController

	include Auth::Concerns::ControllerSmsOtpConcern
	  
	  respond_to :html,:js,:json

	  ##CALLED WHEN THE USER HAS ENTERED HIS MOBILE NUMBER, SO THAT HE GETS ANOTHER OTP
	  def send_sms_otp
	  	resource_params = permitted_params
	  	if resource = User.where(:additional_login_param => resource_params[:additional_login_param]).first
	  		resource.send_sms_otp
	  	else
	  		not_found
	  	end 
	  	respond_to do |format|
  		  format.json {head :ok }
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
	  	respond_with({:verified => (resource.additional_login_param_status == 2)})
	  end


	  def permitted_params
	  	if action_name == "resend_sms_otp"
	  		params.permit(:resource_collection_path)
	  	else
	  		params.fetch(:user,{}).permit(:additional_login_param,:otp)
	  	end
	  end	

end