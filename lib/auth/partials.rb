module Auth
	module Partials
		# a helper method to get the name of the additional login param new otp partial.
		# used in the auth/views/registrations/create.js.erb,
		# because there resolving to a nil value in case the additional_login_param_new_otp_partial is not defined, throws an error, even if the if condition for an additional login param is not entered, since its a js.erb.
		# so the solution was to return a default value as the sign up success invalid content html erb. 
		# this will never be actually hit, but the js erb checks whether the partial exists, even if the if condition where that statement lies is never even reached.
		def self.additional_login_param_new_otp_partial(resource)
			Auth.configuration.auth_resources[resource.class.to_s.capitalize][:additional_login_param_new_otp_partial] or 'auth/modals/sign_up_success_inactive_content.html.erb'
		end
	end
end