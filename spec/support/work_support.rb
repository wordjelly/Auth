module WorkSupport
	def clean_all_work_related_classes
			Auth::Shopping::Product.delete_all
			Auth.configuration.location_class.constantize.delete_all
			Auth.configuration.user_class.constantize.delete_all
			Auth::Work::Schedule.delete_all
			Auth::Work::Minute.delete_all
	end
end
RSpec.configure do |config|
	config.include WorkSupport, :type => :request
	config.include WorkSupport, :type => :model
end