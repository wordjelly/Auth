

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


## Devise Configuration File

Create a configuration file for devise, in initializers.
We recommend setting scoped_views = true, so that devise will look for views and controllers and mailers in the folder that belongs to the resource, and not the general devise folder.

Any other devise option that you want to configure you can do here. It will override the configuration that is provided in the engine.

N.B: The engine does not in any way change anything in the devise default configuration file. Everything there is left untouched.

```
# config/initializers/devise.rb

Devise.setup do |config|
  config.scoped_views = true
end
```

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

### User Model

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

config.user_class = "User"

end
```

#### User Model Creation

Now create A 'User' Model as follows:

```
# app/models/user.rb
class User < Auth::User



end
```


#### Parameter Sanitizer

Create A Parameter Sanitizer, this decides which parameters will be permitted while sign_up or account update.
Place it in lib/{your_model_name}, and name it parameter_sanitizer.rb
It should look like this:

Refer to Devise#Parameter_Sanitizer for more information.

```

# lib/user/parameter_sanitizer.rb

class User::ParameterSanitizer < Devise::ParameterSanitizer

  def initialize(resource_class, resource_name, params)

    super(resource_class, resource_name, params)

    permit(:sign_up, keys: Auth.configuration.auth_resources[resource_class.to_s][:login_params]) 
    
    # if you wanted to permit an additional parameter for the user model at the time of sign up, then do as follows:
    
    # permit(:sign_up, keys: Auth.configuration.auth_resources[resource_class.to_s][:login_params] + [:another_param])

    # remember to add gcm_token here if you plan to enable notifications for android.

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

Add the following to your user model so that devise notification emails are also queued to the job queue.

```
#app/models/user.rb

class User
include Auth::Concerns::UserConcern
...
  
  ## read comments for this in auth/spec/dummy/app/models/user.rb
  def send_devise_notification(notification, *args)
      puts "sending devise notification."
      devise_mailer.send(notification, self, *args).deliver_later
  end
end
```

#### Mailer Configuration + Email CSS

The gem comes prepackaged with 'premailer-rails'. You can refer to its documentation for more details.

A. Mailer for Notifications:

If you use the Auth::Notify class provided by the gem for notifications, then that class needs a mailer to send emails.
To configure this, you need to create a mailer that inherits from Auth::Notifier.

Here is what Auth::Notifier looks like:

```
# auth/app/mailers/auth/notifier.rb

class Auth::Notifier < ::ApplicationMailer
  default from: "from@example.com"
  ## make sure that anything going into this argument implements includes globalid, otherwise serialization and deserialization does not work.
  def notification(resource,notification)
    @resource = resource
    @notification = Auth.configuration.notification_class.constantize.new
    mail to: "someone@gmail.com", subject:  "Hi first notification"
  end
end
```

So you need to create a mailer class and have it inherit from Auth::Mailer, place it in your app/mailers directory

Do this by running the following command from the command line:

```
rails g mailer MyNotificationMailer
```

Then edit the file created so that it looks like this:

```
# app/mailers/my_notification_mailer.rb

class MyNotificationMailer < Auth::Notifier
    
end
```

Now this mailer will be used to send any notification emails.

Here is how the inheritance takes place

              Your App's ApplicationMailer
                          |
                          |
                          |
                    < Auth::Notifier
                          |
                          |
                          |
                  < MyNotificationMailer


The generate command creates a bunch of files and here is what they all do:

In app/views/layouts : 

It creates a basic __mailer.html.erb__, and __mailer.text.erb__. These are layouts that will be used by default for any email sent out from your app. Whether for notification or devise or anything else. The ApplicationMailer by default uses "mailer.html.erb" as its layout file.

In app/views/my_notification_mailer :

This directory is blank by default. Here you can place views that you want to have rendered, inside the layouts mentioned above. 


So basically the flow is as follows;

                        Somebody calls 
                    the #notification def
                      on the mailer which 
                  inherits from Auth::Notifier
                              |
                              |
                              |
                              |           
                    this def looks for a view
                         to render the 
                       email in , in the 
                            folder 
                          app/views/
                    mailer_class_name(in this case MyNotificationMailer)
                              |
                              |
                              |
                              |
                              |
              those views are rendered in the layout
                 which defaults to mailer.html.erb.

The only missing link in all this , is how does the caller know the name of the mailer class that you use in your app, for the purpose of sending notifications? 

Well that has to be set in the configuration file:

```
config.mailer_class = "MyNotificationMailer"
```

The layout mentioned above can be changed by explicitly setting the layout option in your mailer, as follows:

```
# app/mailers/my_notification_mailer.rb

class MyNotificationMailer < Auth::Notifier

default from: "from@example.com"
layout 'whatever_layout_you_want'

end
```

You can set many options in mailers. Refer to documentation of ActionMailer for this purpose.

Pending here : basic notification, notification tests, and webhooks.


B. Mailer for Devise Emails:

To use your own views for the devise emails, do as follows:

1. If you set config.scoped_views as true in the devise.rb initializer, then create a folder as follows: 

app/views/{your_resource_pluralized}/mailer

In this folder you can override three files: 

a.confirmation_instructions.html.erb
b.reset_password_instructions.html.erb
c.unlock_instructions.html.erb


For these views to use the default mailer layout of the app, you must add this line at the top of devise.rb initializer.


```
# config/initializers/devise.rb

Devise::Mailer.layout "mailer"
Devise.setup do |config|
  # whatever
end
```

To create a custom mailer for devise use this tutorial:

If you want to do that, refer to this [tutorial](https://www.ajostrow.me/articles/custom-devise-emails), you basically have to create a custom_mailer, like we created above and have it inherit from DeviseMailer.

C. Any Other Mailer:

Just run 

```
rails g WhateverMailer
```

Everything that follows is similar to point A.


D. How to add CSS to Emails

The gem 'premailer-rails' is present by default in the engine.
All you need to do is add a link to the css files , in the <head></head> tags of the layout, that is defined in your mailer. In case you haven't defined any mailer, then it will default to mailer.html.erb. So assuming your layout is mailer.html.erb, here is what it should look like:

```
# app/views/layouts/mailer.html.erb

<html>
  <head>
    <%= stylesheet_link_tag 'application.css', media: 'all' %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>

```

Now in the view that corresponds to your mailer def, add styles from that stylesheet as usual.

eg:

```
# views/users/mailer/confirmation_instructions.html.erb
# assuming that your stylesheet uses materialize-css

<a class="blue-text">Hi this text should be in blue</a>
<a class="teal-text fw-24">Hi this text should have a font weight of 24, and should be teal</a>
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

### Mobile-Number Sign Up:

To allow users to sign up by mobile-number do the following:


#### Configuration File

Modify the config.auth_resources in the configuration file so that it looks like this:

```
# config/initializers/preinitializer.rb

config.auth_resources = {
  "User" => {
    :login_params => [:email,:additional_login_param],
    :additional_login_param_name => "mobile"
  }
}

``` 

#### Parameter Sanitizer

Modify the Parameter Sanitizer created above to permit the 'additional_login_param' as follows:

```
# lib/user/parameter_sanitizer.rb

class User::ParameterSanitizer < Devise::ParameterSanitizer

  def initialize(resource_class, resource_name, params)

    super(resource_class, resource_name, params)
    
    permit(:sign_up, keys: Auth.configuration.auth_resources[resource_class.to_s][:login_params] + [:additional_login_param])

    permit(:account_update, keys: Auth.configuration.auth_resources[resource_class.to_s][:login_params] + [:additional_login_param])

  end

end
```

#### User Model

The engine provides an SMSOtpConcern, to be mixed into the User model.
This Concern adds a couple of callbacks and methods all hooking into the sign-up process. 
You only need to override two of them. Basically the Engine needs to know how to send the user the Otp message, and also how to verify the code entered by the user is valid.
This concern is to be used in conjunction with the _OtpController_ which is described later.
These methods described below are called from the OtpController, at various points.
Hence only include this concern in your user model, after you have also specified the name of the otp controller in the configuration file.


__Including the SmsOtpConcern__


```
# app/models/user.rb

class User
  include Auth::Concerns::UserConcern
  include Auth::Concerns::SmsOtpConcern
end

```

__How to specify method to send Sms Otp?__

Override this method as follows:

```
# app/models/user.rb

# remember to call super before specifying how your app sends the sms.

# In the code below, we use the built in OtpJob provided by the engine, to send the sms. This currently only works for INDIAN mobile numbers.

# The OtpJob is a delayed job, provided by the engine.

def send_sms_otp
  super
  OtpJob.perform_later([self.class.name.to_s,self.id.to_s,"send_sms_otp"])
end
```

__How to verify the sent otp?__

Override this method as follows:

```
# app/models/user.rb

# remember to call super(otp) before specifying how your app verifies the code entered by the user.

# here too, we use the OTPJob provided by the engine, to verify the code. This also currently works only for INDIAN mobile numbers.

def verify_sms_otp(otp)
    super(otp)
    OtpJob.perform_later([self.class.name.to_s,self.id.to_s,"verify_sms_otp",JSON.generate({:otp => otp})])
    
end

```

__How to validate the mobile number?__

Override this method as follows:

```
# app/models/user.rb

# the engine provides a built-in validation function for the additional login parameter that is run before the sign up process, or update process. You can override this def as per your sign up parameter.

# code below is adjusted for INDIAN MOBILE NUMBERS

def additional_login_param_format
   
    if !additional_login_param.blank?
      
      if additional_login_param =~/^([0]\+[0-9]{1,5})?([7-9][0-9]{9})$/
        
      else
        
        errors.add(:additional_login_param,"please enter a valid mobile number")
      end
    end
  end 

```

#### Otp Controller

It is necessary to create a controller , that will include the otpconcern provided by the engine, like so:

```
#app/controllers/otp_controller.rb

class OtpController < Auth::ApplicationController
  include Auth::Concerns::OtpConcern
end

```

You must now enter the name of the otp controller in the configuration file, as follows:

```
# config/initializers/preinitializer.rb

config.otp_controller = "otp"
```


#### How to generate views for use by the otp controller

Currently the engine only provides modal based views for using with the otp controller, and all these only work with ajax requests.
You can use your own views to be rendered inside the modal.
If you want to use the default views then copy and paste the following into the configuration file.

```
# config/initializers/preinitializer.rb

config.auth_resources = {
  "User" => {
    :login_params => [:email,:additional_login_param],
    :additional_login_param_name => "mobile",
    :additional_login_param_resend_confirmation_message => "Resend OTP",
    :additional_login_param_new_otp_partial => "auth/modals/new_otp_input.html.erb",
    :additional_login_param_resend_confirmation_message_partial => "auth/modals/resend_otp.html.erb",
    :additional_login_param_verification_result_partial => "auth/modals/verify_otp.html.erb"
  }
}

```

#### Redis Configuration

If you use the OtpJob provided by the engine for sms's , i.e you are using Indian Mobile Numbers, you need to enable redis, as a global variable called $redis

To do this create an initializer file called redis.rb and add the following code into it:

```
# config/initializers/redis.rb

cnfg = nil
REDIS_CONFIG = YAML.load( File.open( Rails.root.join("config/redis.yml") ) ).symbolize_keys
dflt = REDIS_CONFIG[:default].symbolize_keys
cnfg = dflt.merge(REDIS_CONFIG[Rails.env.to_sym].symbolize_keys) if REDIS_CONFIG[Rails.env.to_sym]
$redis = Redis.new(cnfg)
# To clear out the db before each test
puts "FLUSHING REDIS DB SINCE ENV IS DEVELOPMENT."
$redis.flushdb if Rails.env = "development"

```

Now create a file called redis.yml in your config folder, and add the necessary details based on your development environment.

```
# config/redis.yml

default:
  host: localhost
  port: 6379
development:
  db: 0
#  namespace: appname_dev
test:
  db: 1
#  namespace: appname_test
production:
  db: 2
  host: 192.168.1.100
#  namespace: appname_prod

```

#### API Keys

If you are using the OtpJob for Indian Sms's you need to provide an api key. This key applies to TwoFactorOtp a sms gateway api only.
In the configuration file do the following:

```
config/initializers/preinitializer.rb

# you can add all the api keys you use in your app under this key, so that they are easy to find and reference.

config.third_party_api_keys = {
  :two_factor_sms_api_key => "ac79bc21-6d31-11e7-94da-0200cd936042" 
}

```

## EDGE CASES : I SIGN UP, AND THEN CLOSE SITE, NOW WANT TO RESEND OTP, HOW TO DO IT? 

--------------------------------------------------------------------


### How to do OAuth Authentication

The engine currently supports OAuth with Google and Facebook. 
Do the following :

#### Google OAuth:

To get your api key and secret do as follows:

Go to Google Developer console ->

Create A New Project ->

Now Click on Google-Plus-Api, GMail-Api and any other Api that you want, when you go to the Api, click enable ->

Enable as many as you want ->

Now Click on Credentials in the side-bar ->

Now Click on OAuth-Consent-Screen. ->

Now just enter a name for the project (GitHub-Documentation) ->

Now click "Save" ->

Now click on credentials in the top bar ->

Now click on "Create Credentials" ->

Now click on "OAuth-Client-Id" ->

Now in the popup box, fill in the __Authorized Redirect Urls__ with the redirect callback url.

Go to your command line and call

```
bundle exec rake routes
```

In the routes look for the route that says:

__google_oauth2_omniauth_callback__

Now take that route path, and prefix it with :

http://localhost:3000/-----whatever_path-----

and paste this in the authorized redirect urls.



For eg: If the model is User, and the mount path was /authenticate, you will paste a route as follows:

__http://localhost:3000/authenticate/omniauth/google_oauth2/callback__

Then click create, maybe click it again till you get the dialog that gives you the app_id and the secret.

It will then provide you with the client id, and client secret, go to the devise.rb configuration file and under the commented out omniauth section, add the following:

Now go and add the following lines, by creating a key called config.oauth_credentials:

```
config.oauth_credentials = {
    "google_oauth2" => {
      "app_id" => "your app id",
      "app_secret" => "your app secret",
      "options" => {
        :scope => "email, profile",
            :prompt => "select_account",
            :image_aspect_ratio => "square",
            :image_size => 50
      }
    }
  }

## Also add a key called host_name, since this is used inside GoogleOAuth2.
## the host name should be the same host that is registered in the oauth credentials screen as the redirect url host
## this is necessary while doing mobile based oauth authentication.

config.host_name = "http://localhost:3000"

```

#### Facebook OAuth:

To Authenticate with Facebook do the following:

Go to the following [link](http://developers.facebook.com/apps)

If you are not signed in to facebook, sign in, and then if you are not "Registered" as a developer account, it will ask you to register, do that.

After that click "Create New App" on the top right side.

After that go and choose Dashboard.
Then go to the __FaceBook-Login__ under the __Products__ section in the Dashboard.
It will give options namely, IOS, Android, and some others.
Choose "Web" and enter the web page url as "http://locahost:3000"

Now click save.
Then go the left hand side of the page and click "Settings"

Leave all the settings as default and go and add the callback url, as per your app.

Then click save

Now go to dashboard and pick up the api_key and api_secret, and copy and paste it as follows, in the configuration file:

```
config.oauth_credentials = {
    "facebook" => {
      "app_id" => "1834018783536739",
      "app_secret" => "c1eb040ecc9d5bb1fd6f518169010420",
      "options" => {
        :scope => 'email',
        :info_fields => 'first_name,last_name,email,work',
        :display => 'page'
      }
    }
  }
```

## EDGE CASES : SIGNED IN FROM FACEBOOK, WHAT HAPPENS IF WE TRY TO SIGN IN FROM GOOGLE, MOBILE NUMBER INTERACTION FROM OAUTH ACCOUNT, TRYING TO SIGN UP BY SAME EMAIL AS OAUTH ACCOUNT.

--------------------------------------------------------------
### Token Authentication for API Access

If you do not want token authentication, add the following in the configuration file:

This has not been extensively tested, and is currently __not__ recommended. For one, the Shopping Api will throw extensive errors.

```
config.enable_token_auth = nil
```

--------------------------------------------------------------
## Creating An Admin Model

Any model that you want to have as admin by default should define the following attribute as true;

```
## app/models/whatever.rb
class Whatever
  include Auth::UserConcern
  field :admin, type: Boolean, default: true  
end
```
------------------------------------------------------------------
## Shopping API

To use the shopping api you need to do the following:

### Create the Models


#### A Cart Model

```
# app/models/shopping/cart.rb

class Shopping::Cart < Auth::Shopping::Cart
  
end
```

#### A Cart Item Model

```
# app/models/shopping/cart_item.rb

class Shopping::CartItem < Auth::Shopping::CartItem

end
```

#### A Payment Model

```
# app/models/shopping/payment.rb

class Shopping::Payment < Auth::Shopping::Payment
  
  ## if you want to do payments in India only, then use the provided concern as follows ->
  include Auth::Concerns::Shopping::PayUMoneyConcern

end
```

#### A Product Model

```
# app/models/shopping/product.rb

class Shopping::Product < Auth::Shopping::Product

end
```

### A Discount Model 

```
# app/models/shopping/discount.rb
class Shopping::Discount < Auth::Shopping::Discount

end
```

### Create the Corresponding Controllers

#### A Carts Controller

```
# app/controllers/shopping/carts_controller.rb

class Shopping::CartsController < Auth::Shopping::CartsController


end
```

#### A CartItems Controller

```
# app/controllers/shopping/cart_items_controller.rb

class Shopping::CartItemsController < Auth::Shopping::CartItemsController

end
```

#### A Payments Controller

```
# app/controllers/shopping/payments_controller.rb

class Shopping::PaymentsController < Auth::Shopping::PaymentsController
  

end
```

#### A Products Controller

```
# app/controllers/shopping/products_controller.rb

class Shopping::ProductsController < Auth::Shopping::ProductsController

end
```

### A Discounts Controller

```
# app/controllers/shopping/discounts_controller.rb

class Shopping::DiscountsController < Auth::Shopping::DiscountsController

end
```


### Modify the configuration file 

```
# config/initializers/preinitializer.rb

config.cart_item_controller = "shopping/cart_items"
config.cart_item_class = "Shopping::CartItem"

config.cart_controller = "shopping/carts"
config.cart_class = "Shopping::Cart"

config.payment_controller = "shopping/payments"
config.payment_class = "Shopping::Payment"

config.product_controller = "shopping/products"
config.product_class = "Shopping::Product"

config.discount_controller = "shopping/discounts"
config.discount_class = "Shopping::Discount"

## refer to the section on payment gateways later, for information on this configuration.
## the configuration you see here is only applicable if you are using the payumoney concern in your payments_controller, that enables payments in india.
config.payment_gateway_info = {:key => "gtKFFx", :salt => "eCwWELxi", :CardName => "Any Name", :CardNumber => "5123456789012346", :CVV => "123", :Expiry => "May 2017"}
```

If you are using PayUMoney, remember to incorporate the following into your payments controller :


```
# my_payments_controller.rb

class MyPaymentsController < Auth::Shopping::PaymentsController
  include Auth::Concerns::Shopping::PayuMoneyConcern
end

```

Also include, at the top of your routes file:

```
# config/routes.rb

Rails.application.routes.default_url_options[:host] = Auth.configuration.host_name

Rails.application.routes.draw do
  ....
  ## and inside the routes remember to add a route for the callback from payumoney as follows(it depends on what is your payments path, but in case it is like shopping/payments, then you need to add this route.)
  post 'shopping/payments/:id', to: 'shopping/payments#update', as: "payumoney_payment_gateway_callback_path"

end

```





After doing this, run the following from the command line:

```
bundle exec rake routes
```

Check routes for cart, cart item, payment, product and discount are present.


### How to pass your own permitted params to any of the Shopping Classes:

Assuming that you want to permit additional params to the cart_items_controller, add this to your controller class

```
## here : description, sample_type and public are the additional parameters that you want to permit.

def permitted_params
  super.deep_merge(params.permit({cart_item: [:description,:sample_type,:public]}))
end
```

#### TODO : Add tests to all shopping controller to evaluate that additional parameters can be passed and saved/updated.


### Views for Shopping API

The engine offers in built views for the Shopping API. These are all html based views. No js / ajax views are supported in built.
You can override all the views by creating a folder with the same name as the controller actions.
None of the shopping controllers directly render any view. All of them just call "respond_with {whatever_object}".

--------------------------------------------------------------
## Search API


### ElasticSearch Configuration

The wj-mongoid-elasticsearch gem is required by default in the engine. The engine does no other configuration. If you want to alter the port/ any other elasticsearch options, you can place the necessary modifications in the preinitializer file. The following adds a prefix to all indices from the app.




```
## config/preinitializer.rb

## For eg if you want to add a prefix to all the app indices, do this, always makesure it is lowercase:
Mongoid::Elasticsearch.prefix = 'doggy'

## To add other elasticsearch client specific options, you can add them here itself, refer to rspro-mongoid-elasticsearch to see these options.

## After that, you have to do , for every single model that you have added an elastisearch index definition to:

ModelName.es.index.create

## additionally you must add the following lines, to create the indexes for certain models from the engine, which also need elasticsearch.

## will create indexes for the shopping classes and user class, as defined by you in the configuration.
[Auth.configuration.product_class, Auth.configuration.cart_class, Auth.configuration.cart_item_class, Auth.configuration.payment_class, Auth.configuration.discount_class, Auth.configuration.user_class]. each do |cl|

  if ((cl) && (cl.constantize.respond_to? :es))
    puts "CREATING INDEX : #{cl}  , IF IT DOESNT EXIST"
    cl.constantize.es.index.create
  end

end

```


### Adding ElasticSearch to Models:




```
# app/models/whatever.rb


include Auth::Concerns::EsConcern

## make the call to the following function

index_definition = {....}

create_es_index(index_definition)
   
## this must include the names of the fields, that are already defined in the mapping.

def as_indexed_json(options={})
 {
  name: name,
    price: price,
    resource_id: resource_id,
    public: public
 }  
end

```




Two fields __must__ to be included in the mapping:

1. public : "yes/no"
if set to "yes" => it can be searched by any signed in user.
if set to "no" => it can be searched only by the user whose resource_id is the same as the resource_id specified in the record, or any admin user.

2. resource_id : the resource id of the user who owns this record. 

### How to override the index definition of those models where the index definition is inbuilt:

In models where the engine has provided the index definition, like : user, and all shopping models. do the following:





```
#app/models/user.rb

class User 
  
  ## these models which inherit from the engine, already have a constant defined in their respective concerns, called INDEX_DEFINITION.
  ## so you have to use that if you want to specifiy the stock index definition
  ## otherwise you can use your own index definition.
  ## the as_indexed_json is also already defined in their concerns.

end

```


Following lines are to be placed for any model that is using elasticsearch(including the models provided by the engine)

```
  class User 

  include Auth::Concerns::UserConcern
  ## assumes you are using the INDEX_DEFINTION from the user_concern.rb

  create_es_index(INDEX_DEFINITION)

  ## this def must be added otherwise, elasticsearch will dynamically change the index definition to add all the fields from user into the index definition.
  def as_indexed_json(options={})
    {
      name: name,
      email: email,
      additional_login_param: additional_login_param,
      additional_login_param_status: additional_login_param_status,
      resource_id: resource_id,
      public: public
    }
  end

```




### How user access works for search:


### Search Response format:

-------------------------------------------------------------
## User Permissions and Token Concern:

### Lookup_Resource

### Signed In Resource

### Model level assignments

### Proxy Resource Class and Id

### Which instance attributes are reserved in controllers.

### How to Protect A Controller with Authentication

### How to Get the currently signed in user

### How to use owner_concern

### How to assign variables at the controller level

### How to use the m_client


### DocVersion vs Version vs MongoidVersionedAtomic

doc_version was added into OwnerConcern.
I didn't use the name "version" to avoid confusion.
MongoidVersionedAtomic is used only in UserConcern.

OwnerConcern is not used in UserConcern, so there would not have been any problem adding a :version field into OwnerConcern, but decided to avoid confusion and use a different name.

doc_version is by default initialized to 0. It is expected to be queried, whenever the object is saved, in a find_and_modify style, but is not enforced.
Currently it is being used only in the Workflow models in this manner.
-------------------------------------------------------------

## Admin Create Users

No special configuration is needed. The routes are added automatically, and the views and controller are provided by the engine.

Add the following code to the user model to determine how a nofitication will be sent to the user so that they can reset the password after their account has been created by the admin.


The super def, is defined in the user concern, it returns a value "r" which is the reset_password_link, in case the user has a mobile number, otherwise if the user has a confirmed email account, then it sends a reset_password_confirmation message to that account. It does not return anything like "r" if the user has an email, since sending the reset password instructions is handled by devise inside the user_concern itself. 

So in the implementing model, we assume that you use the Notification Concern provided and documented herein, and so you should use the notification concern as below to send an sms to the user with the reset password link.

"Noti" in the below code block is the class created in your app that inherits the Notification Concern. Refer to the documentation of the Notification System for more details.

Payment_id  is just an arbitary variable. It has no special meaning.

```
# app/models/user.rb

def send_reset_password_link
  super.tap do |r|
    if r
        notification = Noti.new
        resource_ids = {}
        resource_ids[User.name] = [self.resource_id]
        notification.resource_ids = JSON.generate(resource_ids)
        notification.objects[:payment_id] = r
        notification.save
        Auth::Notify.send_notification(notification)
        
    else
      puts "no r."
      
    end
  end
end
```


-------------------------------------------------------------
## Add Recaptcha To Your Site

In the configuration file add the following:


-------------------------------------------------------------
## Add Notifications To Your Site

To Add Notifications to your app, do the following:

### Configuration File

```
# config/initializers/preinitializer.rb

Auth.configuration do |config|

# all the usual configuration

config.notification_class = "Noti"
config.notification_response_class = "NotiResponse"

end

```

### Models

Create two new models

1. One model to handle the notification class.

Here you can override various methods for the purpose of notification.

```
# app/models/noti.rb
class Noti
  include Auth::Concerns::NotificationConcern
 
  def format_for_sms(resource)
    ## in our case we are using two factor so it needs some parameters to be sent in.
    ## it expects:
    ## to_number,template_name,var_hash,template_sender_id
    ## so here we return an array of arguments.
    response = {}
    response[:to_number] = resource.additional_login_param

    ## the following three are things which will be specific to the template configured in twofactor.
    response[:template_name] = "test2"
    response[:var_hash] = {var1: resource.id.to_s, var2: objects[:payment_id]}
    response[:template_sender_id] = "PATHOF"
    
    response
  end

  def send_sms_background(resource)
    
    job_arguments = [resource.class.name.to_s,resource.id.to_s,"send_transactional_sms",JSON.generate({:notification_id => self.id.to_s, :notification_class => self.class.name.to_s})]
    #Auth::SidekiqUp.sidekiq_running(JSON.generate(job_arguments)) do 
    k = OtpJob.perform_later(job_arguments)
      puts "send sms background : perform_later returns: #{k.to_s}"
    #end
  end


  def send_email_background(resource)
    job_arguments = [resource.class.name.to_s,resource.id.to_s,"send_email",JSON.generate({:notification_id => self.id.to_s, :notification_class => self.class.name.to_s})]
    #Auth::SidekiqUp.sidekiq_running(JSON.generate(job_arguments)) do 
    k = OtpJob.perform_later(job_arguments)
    puts "send email background : perform_later returns: #{k.to_s}"
    #end
  end
  


end
```

2. The other model to handle the response from the remote services to the notifications that you sent out.

```
## app/models/noti_response.rb
class NotiResponse
  include Auth::Concerns::NotificationResponseConcern
  
  def set_webhook_identifier(response)
    Auth::Mailgun.set_webhook_identifier(self,response)
    Auth::TwoFactorOtp.set_webhook_identifier(self,response)
  end

end
```


### Controllers

Create A Controller to handle webhooks from the remote services that will handle the responses to your notifications.

Inherit from the Auth::WebhooksController
The Auth::WebhooksController does nothing much other than skipping verification of authenticity tokens.

```
# app/controllers/webhooks_controller.rb
class WebhooksController < Auth::WebhooksController
  def sms_webhook 
    ## send to a background job in the respective module.
    OtpJob.perform_later([nil,nil,"sms_webhook",JSON.generate(params)])
    render :nothing => true, :status => 200
  end

  def email_webhook
    ## send to a background job in the respective module.
    OtpJob.perform_later([nil,nil,"email_webhook",JSON.generate(params)])
    render :nothing => true, :status => 200
  end
end
```

You need to configure routes in your app, to service whatever methods you specify in your webhooks_controller.

------------------------------------------------------------

## Image Concern

The engine uses Cloudinary to upload images.

### Configuration

1. Place the cloudinary.yml file that you get from cloudinary in your config folder
2. Optionally specify the image class and image controller in the config file (auth)

### Layout

3. Add the following tag in your main application layout in the head section.

```
<%= cloudinary_js_config %>
<%= javascript_link_tag  "https://widget.cloudinary.com/global/all.js" %>
```

### Views

4. In whichever view you want to show the button to uplaod the image, add the following line :

```
<%= render :partial => "auth/images/image_concern.html.erb" %>
```

Ensure that there is an instance variable called "@model" available in that view.

Current support is to do one upload at a time.


### Javascript

Create a file called "images.js". Make sure that it is included by application.js

Add the following code into it.

```
// images.js

// this ensures that it works even when turbolinks is enabled
document.addEventListener("turbolinks:load", function() {
  $('#upload_widget_opener').cloudinary_upload_widget(
  { cloud_name: "doohavoda", api_key:"393369625566631", upload_signature: generateSignature,
  public_id: $("#image_id").text()},
  function(error, result) { console.log(error, result) });
})

var generateSignature = function(callback, params_to_sign){
  params_to_sign["_id"] = $("#image_id").text();
  params_to_sign["parent_id"] = $("#parent_id").text();
  params_to_sign["parent_class"] = $("#parent_class").text();
    $.ajax({
      url     : "/auth/images",
      type    : "POST",
      dataType: "text",
      data    : { image: params_to_sign
            },
      complete: function() {console.log("complete")},
      success : function(signature, textStatus, xhr) {
       console.log("signature returned is:");
       console.log(signature);
       callback(signature); },
      error   : function(xhr, status, error) { console.log(xhr, status, error); }
    });
}

```

1. Replace your cloudinary api_key for api_key, and your cloud_name for cloud_name.

2. In the generateSignature function, add the url that points to the create_image_path for your application. In case you used the default image_controller class, you don't need to change this in any way.

That's it.

-------------------------------------------------------------------

## BarCode Concern

This engine uses Qagga Js to read barcodes

## Configuration

In the configuration file set the following:

```

```