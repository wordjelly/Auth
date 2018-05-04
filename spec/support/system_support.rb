module SystemSupport

	## @return[Auth::System::Wrapper]
	def get_wrapper_from_file(file_path)
		JSON.parse(IO.read(file_path))
	end

end

RSpec.configure do |config|
	config.include SystemSupport, :type => :request
	config.include SystemSupport, :type => :model
end