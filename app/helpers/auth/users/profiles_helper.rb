module Auth::Users::ProfilesHelper

	##@used_in: views/users/profiles/_user_data.html.erb
	##@resource[Object]: a Devise resource
	##@returns[Hash]: a hash with key: resource, value -> jsonified representation of whatever data you want to store for that resource 
	def user_data(resource)
		{resource: {:id => resource.id.to_s}}
	end


	
end
