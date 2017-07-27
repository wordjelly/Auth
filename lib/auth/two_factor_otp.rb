module Auth
	module TwoFactorOtp

		def auth_gen(resource_id,resource_phone_number)
			puts "--entered auth gen with params #{resource_id} and phone number #{resource_phone_number}"
			clear_redis_user_otp_hash(resource_id)
			puts "--came after clearing the redis hash."
			if Auth.configuration.third_party_api_keys[:two_factor_sms_api_key].nil?
				puts "--no api key found"
				log_error_to_redis(resource_id,"no api key found for two_factor_sms_otp")
			else
				puts "--running request"
				response = Typhoeus.get("https://2factor.in/API/V1/#{Auth.configuration.third_party_api_keys[:two_factor_sms_api_key]}/SMS/+91#{resource_phone_number}/AUTOGEN")
				if response.code == 200
					puts "--response code is 200"
					response_body = JSON.parse(response.body).symbolize_keys
					puts "---response body is:"
					puts response_body.to_s
					if response_body[:Status] == "Success"
						puts "--response status is success"
						$redis.hset(resource_id.to_s + "_two_factor_sms_otp","otp_session_id",response_body[:Details])
					else
						puts "--response status is failure"
						log_error_to_redis(resource_id,response_body[:Details])
					end
				else
					puts "--response code is non 200"
					log_error_to_redis(resource_id,"HTTP Error code:"+ response.code.to_s)	
				end
			end

		end

		def verify(resource_class,resource_id,user_provided_otp)
			puts "came to verify the otp."
			if Auth.configuration.third_party_api_keys[:two_factor_sms_api_key].nil?
				log_error_to_redis(resource_id,"no api key found for two_factor_sms_otp")
			else
				otp_session_id = $redis.hget(resource_id.to_s + "_two_factor_sms_otp","otp_session_id")
				if otp_session_id.nil?
					log_error_to_redis(resource_id,"No otp session id found, please click \"resend otp message\" and try again")
				else
					response = Typhoeus.get("https://2factor.in/API/V1/#{Auth.configuration.third_party_api_keys[:two_factor_sms_api_key]}/SMS/VERIFY/#{otp_session_id}/#{user_provided_otp}")
					if response.code == 200
						response_body = JSON.parse(response.body).symbolize_keys
						if response_body[:Status] == "Success"
							##suppose here we say additional parameter confirmed
							##then when we have to sign in user, we just need to bypass the active_for_authentication,
							##and dont touch anything else.
							resource = resource_class.find(resource_id)
							
							resource.additional_login_param_status = 2
							
							resource.save
							
							##this is an attribute accessor so it being set to 2 means that the otp was accurately verified.
							resource.additional_login_param_per_request_status = 2

							clear_redis_user_otp_hash(resource_id)
						else
							log_error_to_redis(resource_id,response_body[:Details])
						end
					else
						log_error_to_redis(resource_id,"HTTP Error code:"+ response.code.to_s)	
					end
				end
			end
		end

		def log_error_to_redis(resource_id,error)
			puts "redis error is:#{error}"
			$redis.hset(resource_id.to_s + "_two_factor_sms_otp","error",error)
		end

		def clear_redis_user_otp_hash(resource_id)
			puts "--came to clear redis otp hash."
			$redis.del(resource_id.to_s + "_two_factor_sms_otp")
		end
		
	end
end