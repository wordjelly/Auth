module Auth::ResourceHelper
	def login_label_text resource
	   ##the login params may be just [:email], or [:email, :additional_login_param]
	   ##if just [:email] -> it should become ["Email"]
	   ##if [:email, :additional_login_param] -> it should become ["Email"."Whatever is the additional login param name specified in the auth_resources"]
	   ##after that we combine the string -> using "Or"
	   login_params_with_additional_login_param_name = Auth.configuration.auth_resources[resource.resource_key_for_auth_configuration][:login_params].map{|c| c = (c == :additional_login_param) ? Auth.configuration.auth_resources[resource.resource_key_for_auth_configuration][:additional_login_param_name].to_s.underscore.capitalize : (c.to_s.underscore.capitalize)}
	   login_params_with_additional_login_param_name.join(" or ")
	end
end
