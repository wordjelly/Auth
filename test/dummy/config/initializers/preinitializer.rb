Auth.configure do |config|

	##the oauth credentails.
	##remember to require the necessary gems in your gemfile.
	config.oauth_credentials = {
		"facebook" => {
			"app_id" => "278055859212434",
			"app_secret" => "aa28a5873807a38dde361665c9732c31",
			"options" => {
				:scope => 'email',
				:info_fields => 'first_name,last_name,email,work',
				:display => 'page'
				}
			},
		"google_oauth2" => {
			"app_id" => "79069425775-njseh8c39qsf24bicherbd3hdvk5o21c.apps.googleusercontent.com",
			"app_secret" => "Wftk1VDJsD7stJxo5GayRSAb",
			"options" => {
				:scope => "email, profile",
		        :prompt => "select_account",
		        :image_aspect_ratio => "square",
		        :image_size => 50
			}
		}
	}

	##the path where you want to mount the authentication routes.
	config.mount_path = "/authenticate"

	##the key should be the name of any model in which the "user_concern" has been included.
	##the value should be controllers that will handle the usual devise pattern.
	##refer to auth/lib/auth/rails/routes.rb
	##default controllers have already been setup in the engine.
	##you can use devise generate to build alternative controllers for your own purposes.
	##remember that the omniauth controller must include the omni_concern, and it should inherit from your application_controller and not the devise_omniauth_callbacks controller.
	config.auth_resources = {
		"User" => {
			"token_auth_options" => {
				fallback: :none,
			    if: lambda { |controller| controller.request.format.json? } 
			}
		}
	}

end
