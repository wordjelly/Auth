module Auth
	module TwoFactorOtp

		def auth_gen(resource_id,resource_phone_number)
			clear_redis_user_otp_hash(resource_id)
			if Auth.configuration.third_party_api_key[:two_factor_sms_api_key].nil?
				log_error_to_redis(resource_id,"no api key found for two_factor_sms_otp")
			else
				response = Typhoeus.get("https://2factor.in/API/V1/#{Auth.configuration.third_party_api_key[:two_factor_sms_api_key]}/SMS/+91#{resource_phone_number}/AUTOGEN")
				if response.code == 200
					response_body = JSON.parse(response.body)
					if response_body[:Status] == "Success"
						$redis.hset(resource_id.to_s + "_two_factor_sms_otp","otp_session_id",response_body[:Details])
					else
						log_error_to_redis(resource_id,response_body[:Details])
					end
				else
					log_error_to_redis(resource_id,"HTTP Error code:"+ response.code.to_s)	
				end
			end

		end

		def verify(resource_class,resource_id,user_provided_otp)
			if Auth.configuration.third_party_api_key[:two_factor_sms_api_key].nil?
				log_error_to_redis(resource_id,"no api key found for two_factor_sms_otp")
			else
				otp_session_id = $redis.hget(resource_id.to_s + "_two_factor_sms_otp","otp_session_id")
				if otp_session_id.nil?
					log_error_to_redis(resource_id,"No otp session id found, please click \"resend otp message\" and try again")
				else
					response = Typhoeus.get("https://2factor.in/API/V1/#{Auth.configuration.third_party_api_key[:two_factor_sms_api_key]}/SMS/VERIFY/#{otp_session_id}/#{user_provided_otp}")
					if response.code == 200
						response_body = JSON.parse(response.body)
						if response_body[:Status] == "Success"
							##suppose here we say additional parameter confirmed
							##then when we have to sign in user, we just need to bypass the active_for_authentication,
							##and dont touch anything else.
							resource_class.find(resource_id).additional_param_confirmed = 1
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
			$redis.hset(resource_id.to_s + "_two_factor_sms_otp","error",error)
		end

		def clear_redis_user_otp_hash(resource_id)
			$redis.hdel(resource_id.to_s + "_two_factor_sms_otp")
		end
		
	end
end