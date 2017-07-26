module Auth::Concerns::ControllerSmsOtpConcern

  extend ActiveSupport::Concern

  included do
      
    ##CALLED WHEN THE USER HAS ENTERED HIS MOBILE NUMBER, SO THAT HE GETS ANOTHER OTP
    def send_sms_otp
      
    end


    ##CALLED WHEN WE WANT TO SHOW THE USER A MODAL TO RE-ENTER HIS MOBILE NUMBER SO THAT WE CAN AGAIN SEND AN OTP TO IT.
    def resend_sms_otp
      
    end

    ##CALLED WHEN THE USER ENTERS THE OTP SENT ON HIS MOBILE
    ##VERIFIES THE OTP WITH THE THIRD PARTY API.
    def verify_otp
      
    end


    ##SHORT-POLLING ENDPOINT TO DETERMINE IF THE OTP WAS VALID.
    ##CALLED IN THE POST-VERIFICATION PAGE.
    def otp_verification_result
      
    end


  end


	  

end