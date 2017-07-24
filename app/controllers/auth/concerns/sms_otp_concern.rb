module Auth::Concerns::SmsOtpConcern

  extend ActiveSupport::Concern

  included do
    
  end

  

  ##
  ## All the methods listed below 
  ## are to be overriden in the confirmations controller
  ## of the daughter app, after including this concern,
  ## as well as the models/concerns/sms_otp_concern, in the 
  ## relevant user model
  ##
  ## also add a permitted params 

  ##GET /request_otp_input?resource_id=xyz, renders the otp modal.
  ##ideally should do the foloowing in the end
  ##json will never be involved with this action.
  ##render_partial -> whatever.
  def show_otp_input_modal

  end

  ##sends the sms otp
  ##GET /send_sms_otp?resource_id=xyz
  ##first send the sms otp and then
  ##here the json will still work.
  ##respond_with (user, location: request_otp_input_path(resource_id))
  def send_sms_otp

  end


  ##GET /verify_otp?resource_id=xyz&otp=1234
  ##first verify , then 
  ##something like this
  ##
  ##respond_to do |format|
  ##  format.html {render_partial(this can be a js erb, designed to do the polling) :verify_otp}
  ##  format.json {render json: @picture}
  ##  format.xml {render xml: @picture}
  ##end
  ##
  ##
  def verify_otp
  	
  end

  

end