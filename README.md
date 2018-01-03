## AUTH

### Why This Gem?

BECAUSE I'M SINGLE AND HAVE NOTHING ELSE TO DO. :) ;) 

#### Authentication

Rails does not offer an all-in-one , plug and play style authentication gem.
This Gem provides:

1. Basic Username, Password Authentication
2. Mobile, Password Authentication
3. OAuth Authentication
4. Token based authentication
5. API authentication
6. Authentication mechanism for Chrome Extensions
7. Standard authentication features like forgot your password, unlock your account and resend confirmation email etc.

#### Notifications

Rails does not provide a simple interface for notifications (email/sms)
This Gem provides a simple Notify class that can be called from anywhere to send email/sms notifications.

#### Shopping Cart

Rails also does not have a shopping-cart gem that works easily.
This Gem provides full shopping cart functionality.

#### Drawbacks:

The only drawback for the moment, is that the gem is built around MongoDb as the database backend. We are working on letting you use adapters for RDBS

### How to Use:

Create a new Rails project from the command line:

```
rails new {your app name} --skip-active-record
```

Edit the Gemfile to include the following, (always use the git source to get the latest version):

```
gem 'auth', :git => "https://github.com/wordjelly/Auth"

## VIMP!!
## also remember to comment out the gem jquery-rails line, since the auth gem provides a specially modified versino of 
jquery rails.

# gem jquery-rails
```

Now from the command line run:

```
bundle update
rails g mongoid:config
```


The Auth gem adds the following additional, essential, dependencies to your application:

1. mongoid (currently only supported database backend)
2. premailer-rails (for formatting emails with normal css)
3. mailgun-ruby (for sending emails)
4. simple-token-authentication (for token authenticatin)
5. devise (devise is used as the authentication base)
6. kaminari-mongoid (for paging mongodb results)
7. materialize-sass (for the css)
8. typhoeus (for making http requests)
9. googl (for the url_shortener module included with the gem)
10. aws-sdk (for background jobs and queues)
11. mongoid-versioned-atomic (a gem that allows document versioning with mongoid, also authored by wordjelly)

## Create A Configuration File

To use the gem , create a __preinitializer__ file in your project's _config/initializers_ folder

A sample file can be found in this gem at the following [location](https://github.com/wordjelly/Auth/blob/master/spec/dummy/config/initializers/preinitializer.rb) : _spec/dummy/config/initializers/preinitializer.rb_

The following shows you how to setup a user and an admin model, with oauth, and token authentication:

The basic configuration file should look like this:

```
Auth.configure do |config|
## all configuration options go here.
end
```

### Mount path

The mount path for the engine is the first thing to configure. Set it as follows:

```
Auth.configure do |config|
## all routes defined by the engine will now be after your project root/authenticate/...engine route...
## eg: http://localhost:3000/authenticate/...whatever engine rout....
config.mount_path = "/authenticate"
end
```

### User and Admin Model

To configure users you need create a key called __config.auth_resources__ in the config file.
Let us say that you want to have a model called "User" which should have full sign in functionality, using email.
__Please note that it is compulsory to add "email" as the first login param__ 
It would be configured as follows:

#### Configuration File

```
Auth.configure do |config|

## all routes defined by the engine will now be after your project root/authenticate/...engine route...
## eg: http://localhost:3000/authenticate/...whatever engine rout....

config.mount_path = "/authenticate"

## Users

config.auth_resources = {
  "User" => {
    :login_params => [:email]
  }
}

end
```

#### User Model Creation

Now create A 'User' Model as follows:

```
# app/models/user.rb
class User

include Auth::Concerns::UserConcern

end
```


#### Parameter Sanitizer

Create A Parameter Sanitizer, this decides which parameters will be permitted while sign_up or account update.
Place it in lib/{your_model_name}, and name it parameter_sanitizer.rb
It should look like this:

Refer to Devise#Parameter_Sanitizer for more information.

```
class User::ParameterSanitizer < Devise::ParameterSanitizer

  def initialize(resource_class, resource_name, params)

    super(resource_class, resource_name, params)

    permit(:sign_up, keys: Auth.configuration.auth_resources[resource_class.to_s][:login_params]) 
    
    # if you wanted to permit an additional parameter for the user model at the time of sign up, then do as follows:
    
    # permit(:sign_up, keys: Auth.configuration.auth_resources[resource_class.to_s][:login_params] + [:another_param])

    permit(:account_update, keys: Auth.configuration.auth_resources[resource_class.to_s][:login_params])

  end

end
```

#### application_controller.rb

You need to tell your application to use this parameter sanitizer as follows

```
# application_controller.rb

  protected

  def devise_parameter_sanitizer
      if resource_class == User
        User::ParameterSanitizer.new(User, :user, params)
      elsif resource_class == Admin
        Admin::ParameterSanitizer.new(Admin,:admin,params)
      else
        super # Use the default one
      end
  end

```

#### application.rb

The parameter sanitizer above will not be used , unless you tell Rails to autoload that file at startup, as follows:

```
# config/application.rb

config.autoload_paths += %W(#{config.root}/lib)
config.autoload_paths += Dir["#{config.root}/lib/**/"]
```

#### Mailer Host configuration

Add this line to you development.rb.

```
config.action_mailer.default_url_options = { :host => 'localhost' }
```

Once you go into production, you will need to add a similar line to production.rb, but with your website name instead. 
This tells rails the origin from where you want to send the 


To receive emails while developing , using the [mailcatcher gem](https://mailcatcher.me/) you need to do the following:

Add this line to development.rb file (or production if you are in production)

```
## Either configure for a local mailer recipient or Mailgun.
## Note that mailgun is provided by default by the gem, using a slightly modified version of the mailgun-ruby gem. Ensure that you don't use the stock mailgun-ruby or it will not work.

## Local MailServer Configuration : eg. for Mailcatcher
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {:address => "localhost", :port => 1025}

## Mailgun configuration.  
  config.action_mailer.delivery_method = :mailgun
  config.action_mailer.mailgun_settings = {
    api_key: 'key-6263360b078081b625182ff17d7a92fd',
    domain: 'sandboxc0248205473845c3a998e44941ee503e.mailgun.org'
  }

```

#### Routes File: Mount the Engine

And finally mount the engine in your routes file with this line:

```
# routes.rb
Rails.application.routes.draw do

mount_routes Auth.configuration.auth_resources

end
```
That's it. No generators or anything else is needed. 


### Use the In-built modals for sign-in/sign-up

The engine uses Materialize css as a css framework. 
It provides a modal for all sign-in / sign-up procedures. 
If you decided to use the engine, for the moment, only the modals work, and they use ONLY ajax requests.
In order to use this do the following:

#### CSS

```
#app/assets/stylesheets.scss

/*
*= require auth/auth_default_css
....
*/
```

#### Javascripts

```
#app/assets/javascripts

//= require auth/auth_modals_and_navbar.js

```

#### Configuration File

In the configuration file you can decide which components you want the engine to provide.

If you want a navbar, alongwith a sign-in / sign-up button on the right side, then in your __preinitializer.rb__ :

```
config.navbar = true
config.brand_name = "Wordjelly"
```

If you also want the sign in modals then add to the config file:

```
config.navbar = true
config.brand_name = "Wordjelly"
config.enable_sign_in_modals = true
```

Also in case you set navbar to true, you have to also tell each auth_resource to be present in the navbar

```

config.navbar = true
config.brand_name = "Wordjelly"
config.enable_sign_in_modals = true
config.auth_resources = {
  "User" => {
    :navbar => true    
  }
}

```

#### Application layout

In your application layout add the following

```
# app/views/layouts/application.html.erb

<body> 
  <!-- for enabling the navbar -->
  <%= render :partial => "layouts/auth/navbar/navbar.html.erb" %>
  
  <div class="container">
    <%= yield %>
  </div>
  
  <!-- for the sign in modals -->
  <%= render :partial => "layouts/auth/modals.html.erb" %>
  
</body>
```

#### Application Controller

Engines cause their own layout to be loaded by default. We want your app's layout to be used. This has to be explicitly specified. Also you must explicitly allow it to respond to html, js and later on will need json in case you are going to use otp controller.

```
# application_controller.rb

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  # this line is necessary to add
  layout 'application'
  respond_to :html,:js,:json
end
```
