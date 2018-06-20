$sns_client = nil
if ENV["AWS_ACCESS_KEY_ID"] && ENV["AWS_SECRET_ACCESS_KEY"] && ENV["AWS_REGION"]
	$sns_client = Aws::SNS::Client.new
else
	Rails.logger.error("Please set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_REGION in your env vars, to use the sns_client. :initializers/aws.rb")
end