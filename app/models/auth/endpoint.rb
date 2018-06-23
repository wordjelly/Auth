class Auth::Endpoint
	
	include Mongoid::Document
		
	field :android_endpoint, type: String
	field :ios_endpoint, type: String
	field :android_token, type: String
	field :ios_token, type: String

	def set_android_endpoint
		
		return unless self.android_token
		
		return if self.android_endpoint
		
		if response = $sns_client.create_platform_endpoint(platform_application_arn: ENV["ANDROID_ARN"], token: self.android_token, attributes: {})
			self.android_endpoint = response.endpoint_arn
		
			self.android_endpoint
		else
		
			nil
		end
	end

	def set_ios_endpoint
		return unless self.ios_token
	end

	## so i have to do what first ?
	## notification objects.
	## and their editing.

	## so it comes down to a few simple things
	## 1. the cart_item has a variables hash.
	## 2. notiications are assigned to each instruction.
	## 2a. they will carry an array of outlinks, as well as how the notification is to be sent.
	## 3a. they will check the time in the variables hash before sending the notification
	## 4a. they will rewire themselves if the time is later than what is in the notification itself.
	## 5a. cycles can directly update cart items which they pertain to, chaning these notification variables.
	## 3. when a cart item is created -> notifications are queued.
	## 4. the time for queueing is defined based on the variables seen in that variables hash.
	## but assume that a cart item is queued. and it is a part of several cycles.
	## in that case, the timings can only be got from those cycles
	## so the cart item has to build its variables from the cycles.
	## where is the cycle going to update its images and videos ?
	## to what ?
	## and i need a place to edit the bullets, instructions, and notifications, and variables.
	## and i have 2 days for all this :)

end