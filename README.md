##AUTH

###Why This Gem?

####ETA <= 1 min

Adding user-authentication to a website is still a frightening process. Users need profiles, images, followers, people they follow and notifications. Not to mention run-of-the-mill username and password functionality. Oh and we forgot to mention OAuth.

These days, most web-services have clients on multiple platforms like Android, IOS, Chrome extensions, JS widgets etc. Imagine you also wanted to build a wordpress-plugin and authenticate your users through that.

There is no Rails Gem that provides a simplistic and easy to configure authentication system that supports all these needs.
Wordjelly-Auth combines Devise, SimpleTokenAuthentication, OmniAuth2 and several other gems to provide a one-fits-all authentication solution.

Furthermore, having an authentication system is not enough without a shiny front-end. Wordjelly-Auth provides users with an optional authentication layout, using MaterializeCss.

The entire installation process requires just ONE initializer file. You do not need to run generators, configure heavy config.rb files, or do anything fancy to get this working. 

##How to use:

1.Add 'wj-auth' to your gemfile

```
Gemfile

gem 'wj-auth'
```

2.In the config/initializers folder of your rails app create a file named 'preinitializer.rb' - the name is important, do not change it.
All the settings that you need to get authentication running, will go into this one file. Most settings are inbuilt defaults, and you only need to configure your oauth credentials and the optional url where all your authentication related routes will be generated.


```
config/initializers/preinitializer.rb

Auth.configure do |config|

	##the oauth credentails.
	config.oauth_credentials = {
		"facebook" => {
			"app_id" => "facebook_app_id",
			"app_secret" => "facebook_app_secret",
			"options" => {
				:scope => 'email',
				:info_fields => 'first_name,last_name,email,work',
				:display => 'page'
				}
			},
		"google_oauth2" => {
			"app_id" => "google_app_id",
			"app_secret" => "google_app_secret",
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

	##This is where you configure the models for which you want to build authentication.
  ##The name of the model should be the key(notice that it is upcased), and the value should be a hash of configuration options.
  ##there are only two options that matter
  ##1):nav_bar => set to true if you want this model to be have a sign_in_{Model_Name} link to appear in your nav-bar, default is false
  ##2):controllers => auth uses devise controllers by default, If you want to use one of your own controllers, add the controller path here. Remember that the controller should inherit from DeviseController, or you will hit errors.
  
  ##You can add as many models as you want.
  
	config.auth_resources = {
		"User" => {
			:nav_bar =>  true
		},
		"Admin" => {
			:controllers => {
				:sessions => "admins/sessions"
			}
		}
	}

end

##Auth uses Recaptcha during user registration. You need to go and get yourself a Recaptcha key and site_secret and add it here. This is not optional, your app will not work without it.
Recaptcha.configure do |config|
	config.site_key  = 'site_key'
  config.secret_key = 'site_secret'
end

```


###To reference engine paths from within the engine:
If you don't do as below, you don't get the mount path prefixed to the url.
```
Engine_Name::Engine.routes.url_helpers.path
```

###To reference app paths from withing the engine:
There is a helper which is created when you mount any engine, called main_app
Use this from within the engine to reference app_paths.
```
main_app.app_path
```

###To reference engine paths from within the app:
While mounting the engine, specify as: mount_as
```
mount_as.engine_path
```

##While testing routes with rspec

1. If you are testing any action that involves a route defined in the engine,
then you need to use the routeset of the engine.
```
routes{Auth::Engine.routes}
```
Furthermore remember that using any path helpers, inside rspec, will give you the path including the mount_prefix(where you mounted the engine), however this path will not be found in the engine routeset above, and you will get a no route matches.
So you have to use raw paths i.e "clients" instead of clients_path because clients_path => mount_prefix/clients, which is not present in the routes defined in the engine. The engine routes contain everything relative to root(/). So whenever testing any action that involves an engine route, use raw paths and define the routeset. 

2. Don't create any actions that involve using an engine route and an app route, because it will be very difficult to test that.
