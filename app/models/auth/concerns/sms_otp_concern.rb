module Auth::Concerns::SmsOtpConcern

	extend ActiveSupport::Concern

	included do 

		def send_devise_notification(notification,*args)
  			##here we have to just adjust it to 
  			puts "Called the smsotpconcern."
  			puts self.attributes
  		end

	end


end

##architecture
##need to have a place where the user can enter his otp and get it 
##verified
##so will need a controller for that
##confirmations controller can be extended to do that
##with additional actions for otp
##the actions would be new_otp
##create which would then 