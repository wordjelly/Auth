module Auth
	module TwoFactorOtp

		TWO_FACTOR_BASE_URL = "http://2factor.in/API/V1/"
		TWO_FACTOR_TRANSACTIONAL_SMS_URL = "/ADDON_SERVICES/SEND/TSMS"
		##returns the string value at the errors keys in the redis hash 
		def check_errors
			$redis.hget(self.id.to_s + "_two_factor_sms_otp","error")
		end

		## to_number : string, indian telephone number, without the preceeding 91
		## template : the two_factor_otp template 
		## example request should look like this
		## "https://2factor.in/API/R1/?module=TRANS_SMS&apikey=#{Auth.configuration.third_party_api_keys[:two_factor_sms_api_key]}&to=#{to_number}&from=#{template_sender_id}&templatename=TemplateName&var1=VAR1_VALUE&var2=VAR2_VALUE"
		## @return[String] session_id
		def send_transactional_sms(args)
			to_number = args[:to_number],
			template_name = args[:template_name]
			var_hash = args[:var_hash]
			template_sender_id = args[:template_sender_id]
			
			url = "https://2factor.in/API/R1/?module=TRANS_SMS"
			
			params = {
				api_key: Auth.configuration.third_party_api_keys[:two_factor_sms_api_key],
				to: to_number,
				from: template_sender_id,
				templatename: template_name,
			}.merge(var_hash)

			response = Typhoeus::Request.new(
			  url,
			  params: params
			).run
			
			JSON.parse(response)["session-id"]
		end

		def auth_gen
			
			#puts "--entered auth gen with params #{self.id} and phone number #{self.additional_login_param}"
			clear_redis_user_otp_hash
			#puts "--came after clearing the redis hash."
			if Auth.configuration.third_party_api_keys[:two_factor_sms_api_key].nil?
				#puts "--no api key found"
				log_error_to_redis("no api key found for two_factor_sms_otp")
			else
				#puts "--running request"
				
				response = send_otp_response

				if response.code == 200
					puts "-- send response code is 200"
					response_body = JSON.parse(response.body).symbolize_keys
					puts "---send response body is:"
					puts response_body.to_s
					if response_body[:Status] == "Success"
						puts "--send response status is success"
						puts "set the redis value to : #{response_body[:Details]}"
						$redis.hset(self.id.to_s + "_two_factor_sms_otp","otp_session_id",response_body[:Details])
					else
						#puts "--response status is failure"
						log_error_to_redis(response_body[:Details])
					end
				else
					#puts "--response code is non 200"
					log_error_to_redis("HTTP Error code:"+ response.code.to_s)	
				end
			end

		end

		def verify(otp)
			
			if Auth.configuration.third_party_api_keys[:two_factor_sms_api_key].nil?
				log_error_to_redis("no api key found for two_factor_sms_otp")
			else
				otp_session_id = $redis.hget(self.id.to_s + "_two_factor_sms_otp","otp_session_id")
				if otp_session_id.nil?
					log_error_to_redis("No otp session id found, please click \"resend otp message\" and try again")
				else

					response = verify_otp_response(otp,otp_session_id)
					if response.code == 200
						response_body = JSON.parse(response.body).symbolize_keys
						if response_body[:Status] == "Success"
							##suppose here we say additional parameter confirmed
							##then when we have to sign in user, we just need to bypass the active_for_authentication,
							##and dont touch anything else.

							self.otp = otp

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
			#puts "redis error is:#{error}"
			$redis.hset(self.id.to_s + "_two_factor_sms_otp","error",error)
		end

		def clear_redis_user_otp_hash
			#puts "--came to clear redis otp hash."
			$redis.del(self.id.to_s + "_two_factor_sms_otp")
		end

		def send_otp_response
			if Auth.configuration.stub_otp_api_calls
				
				OpenStruct.new({code: 200, body: JSON.generate({:Status => "Success", :Details => Faker::Name.name})})
			else
				Typhoeus.get("https://2factor.in/API/V1/#{Auth.configuration.third_party_api_keys[:two_factor_sms_api_key]}/SMS/+91#{self.additional_login_param}/AUTOGEN")
			end
		end

		def verify_otp_response(otp,otp_session_id)
			
			if Auth.configuration.stub_otp_api_calls
				if Auth.configuration.simulate_invalid_otp
					OpenStruct.new({code: 200, body: JSON.generate({:Status => "failed", :Details => "your otp is invalid"})})
				else

					##check the otp, and derive the response based on that.
					##this comparison of comparing the session id, with the opt is just for test purpose.
					##in reality they have nothing to do with each other.
					puts "otp session id is:#{otp_session_id}"
					puts "otp is: #{otp}"
					OpenStruct.new({code: 200, body: JSON.generate({:Status => ((otp_session_id == otp) ? "Success" : "failed"), :Details => "location: two_factor_otp.rb#verify_otp_response, compares otp_session id to provided otp to decide failure or success"})})	
				end
			else
				Typhoeus.get("https://2factor.in/API/V1/#{Auth.configuration.third_party_api_keys[:two_factor_sms_api_key]}/SMS/VERIFY/#{otp_session_id}/#{otp}")
			end
		end
	end
end