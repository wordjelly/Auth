class OtpController < Auth::ApplicationController

	include Auth::Concerns::ControllerSmsOtpConcern
	  
	  respond_to :html,:js,:json

	  ##GET /request_otp_input?resource_id=xyz, renders the otp modal.
	  ##ideally should do the foloowing in the end
	  ##json will never be involved with this action.
	  ##render_partial -> whatever.
	  def new_otp_input
	  	resource = User.find(params[:resource_id]) or not_found
	  	respond_to do |format|
	  	  format.json {render json: resource}
  		  format.js   {render "/auth/confirmations/new_otp_input.js.erb"}
	  	end
	  end

	  ##sends the sms otp
	  ##GET /send_sms_otp?resource_id=xyz
	  ##first send the sms otp and then
	  ##here the json will still work.
	  ##respond_with (user, location: request_otp_input_path(resource_id))
	  ##depends on whether or not the 
	  def send_sms_otp
	  	
	  	##will first need to find_by additional_login_param and status = pending.
	  	##protect with 
	  	##then send to that one.
	  	##then redirect to otp_input.
	  	resource = User.find(params[:resource_id]) or not_found
	  	resource.send_sms_otp
	  	respond_to do |format|
	  		format.json {render json: resource}
	  	end
	  end


	  def resend_sms_otp

	  end

	  ##GET /verify_otp?resource_id=xyz&otp=1234
	  def verify_otp
	  	resource_params = permitted_params
	  	
	  	
	  	resource = User.where(:additional_login_param => resource_params[:additional_login_param], :additional_login_param_status => 1).first 
	  	
	  	resource.verify_sms_otp(resource_params[:otp])
	  	respond_to do |format|
  		  format.json {render json: resource}
  		  format.js   {render "auth/confirmations/_verify_otp.js.erb", locals: {resource: resource}}
  		end
	  end


	  def otp_verification_result
	  	resource = User.find(params[:resource_id]) or not_found
	  	respond_with({:verified => (resource.additional_login_param_status == 2)})
	  end


	  def permitted_params
	  	params.fetch(:user,{}).permit(:additional_login_param,:otp)
	  end	

end