class Users::ConfirmationsController < Devise::ConfirmationsController
	include Auth::Concerns::SmsOtpConcern
	  
	  respond_to :html,:js,:json

	  ##GET /send_sms_otp?resource_id=xyz 
	  ##sends the sms otp again.
	  def send_sms_otp

	  end


	  ##GET /verify_otp?resource_id=xyz&otp=1234
	  def verify_otp
	  	if user = User.find(params[:resource_id])
	  		user.verify(resource_class,resource_id,user_provided_otp)
	  	end
	  	
	  end

end
