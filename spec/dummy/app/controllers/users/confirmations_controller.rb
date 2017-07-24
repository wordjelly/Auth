class Users::ConfirmationsController < Devise::ConfirmationsController
	include Auth::Concerns::SmsOtpConcern
	  
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
	  def send_sms_otp

	  end


	  ##GET /verify_otp?resource_id=xyz&otp=1234
	  def verify_otp
	  	resource = User.find(params[:resource_id]) or not_found
	  	resource.verify_sms_otp(user_provided_otp)
	  	respond_to do |format|
  		  format.json {render json: resource}
  		 ##format.js   {render :partial => ""}
  		end
	  end



end
