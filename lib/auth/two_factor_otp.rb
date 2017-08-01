module Auth
	module TwoFactorOtp

		##returns the string value at the errors keys in the redis hash 
		def check_errors
			$redis.hget(self.id.to_s + "_two_factor_sms_otp","error")
		end

		def auth_gen
			
			puts "--entered auth gen with params #{self.id} and phone number #{self.additional_login_param}"
			clear_redis_user_otp_hash
			puts "--came after clearing the redis hash."
			if Auth.configuration.third_party_api_keys[:two_factor_sms_api_key].nil?
				puts "--no api key found"
				log_error_to_redis("no api key found for two_factor_sms_otp")
			else
				puts "--running request"

				response = Auth.configuration.stub_otp_api_calls ? OpenStruct.new({code: 200, body: JSON.generate({:Status => "Success", :Details => "abcde"})}) : Typhoeus.get("https://2factor.in/API/V1/#{Auth.configuration.third_party_api_keys[:two_factor_sms_api_key]}/SMS/+91#{self.additional_login_param}/AUTOGEN")

				if response.code == 200
					puts "--response code is 200"
					response_body = JSON.parse(response.body).symbolize_keys
					puts "---response body is:"
					puts response_body.to_s
					if response_body[:Status] == "Success"
						puts "--response status is success"
						$redis.hset(self.id.to_s + "_two_factor_sms_otp","otp_session_id",response_body[:Details])
					else
						puts "--response status is failure"
						log_error_to_redis(response_body[:Details])
					end
				else
					puts "--response code is non 200"
					log_error_to_redis("HTTP Error code:"+ response.code.to_s)	
				end
			end

		end

		def verify
			puts "came to verify the otp."
			if Auth.configuration.third_party_api_keys[:two_factor_sms_api_key].nil?
				log_error_to_redis("no api key found for two_factor_sms_otp")
			else
				otp_session_id = $redis.hget(self.id.to_s + "_two_factor_sms_otp","otp_session_id")
				if otp_session_id.nil?
					log_error_to_redis("No otp session id found, please click \"resend otp message\" and try again")
				else

					response = Auth.configuration.stub_otp_api_calls ? OpenStruct.new({code: 200, body: JSON.generate({:Status => "Success", :Details => "abcde"})}) : Typhoeus.get("https://2factor.in/API/V1/#{Auth.configuration.third_party_api_keys[:two_factor_sms_api_key]}/SMS/VERIFY/#{otp_session_id}/#{self.otp}")
					if response.code == 200
						response_body = JSON.parse(response.body).symbolize_keys
						if response_body[:Status] == "Success"
							##suppose here we say additional parameter confirmed
							##then when we have to sign in user, we just need to bypass the active_for_authentication,
							##and dont touch anything else.
							
							self.additional_login_param_status = 2
							
							
							self.save
							
							clear_redis_user_otp_hash
						else
							log_error_to_redis(response_body[:Details])
						end
					else
						log_error_to_redis("HTTP Error code:"+ response.code.to_s)	
					end
				end
			end
		end

		def log_error_to_redis(error)
			puts "redis error is:#{error}"
			$redis.hset(self.id.to_s + "_two_factor_sms_otp","error",error)
		end

		def clear_redis_user_otp_hash
			puts "--came to clear redis otp hash."
			$redis.del(self.id.to_s + "_two_factor_sms_otp")
		end
		
	end
end