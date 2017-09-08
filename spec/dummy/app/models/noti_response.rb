class NotiResponse
	include Auth::Concerns::NotificationResponseConcern
	def set_webhook_identifier
		puts "came to set webhook identifier."
		last_response = self.responses.last
		last_response = JSON.parse(last_response)
		puts "last response parsed as: #{last_response}"
		if last_response["Status"] && last_response["Status"] == "Success"

			self.webhook_identifier = last_response["Details"]
		end
		puts "setting webhook identifier:"
		puts self.webhook_identifier.to_s
	end

	
	
end