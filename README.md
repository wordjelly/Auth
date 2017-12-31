## AUTH

### Why This Gem?

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
```

Now run __bundle update__ from the command line.


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
