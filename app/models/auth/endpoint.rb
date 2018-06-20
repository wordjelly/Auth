class Auth::Endpoint
	
	include Mongoid::Document
		
	field :android_endpoint, type: String
	field :ios_endpoint, type: String
	field :android_token, type: String
	field :ios_token, type: String

	before_save :set_android_endpoint
	before_save :set_ios_endpoint

	def set_android_endpoint
		return unless self.android_token
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


end