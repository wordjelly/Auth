##here add the internal lib files or anything else that is going to be
##needed throughout the app, that was defined or created inside the app itself.
require "auth/omniauth/path"
require "auth/rails/routes"
require "auth/two_factor_otp"
require "auth/mailgun"
require "auth/job_exception_handler"
require "auth/url_shortener"
require "auth/notify"
#require "auth/sidekiq_up"

module Auth
  class Engine < ::Rails::Engine
    #isolate_namespace Auth
    config.generators do |g|
      g.test_framework :rspec
    end
  end

 
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
    
    self.configuration.auth_resources.keys.each do |res|
      ##a skip option must be present on each auth resource.
      if self.configuration.auth_resources[res][:skip].nil?
        self.configuration.auth_resources[res][:skip] = []
      end

      ##a token_auth_options hash must be present on the 
      ##configuration for each resource..
      if self.configuration.auth_resources[res]["token_auth_options"].nil?
        self.configuration.auth_resources[res]["token_auth_options"] = 
        {
          fallback: :exception
          #,
          #if: lambda { |controller| controller.request.format.json? } 
        }
      end
    end
    ##
  end

  class Configuration
    attr_accessor :enable_token_auth
    attr_accessor :oauth_credentials
    attr_accessor :mount_path
    attr_accessor :auth_resources
    attr_accessor :enable_sign_in_modals
    attr_accessor :recaptcha
    attr_accessor :redis_config_file_location
    attr_accessor :third_party_api_keys
    attr_accessor :stub_otp_api_calls
    attr_accessor :simulate_invalid_otp
    attr_accessor :otp_controller
    attr_accessor :cart_item_controller
    attr_accessor :cart_item_class
    attr_accessor :cart_controller
    attr_accessor :cart_class
    attr_accessor :payment_class
    attr_accessor :notification_class
    attr_accessor :payment_controller
    attr_accessor :payment_gateway_info
    attr_accessor :token_regeneration_time
    attr_accessor :do_redirect
    attr_accessor :brand_name
    attr_accessor :notification_response_class
    ## the class used in the user_concern, to send emails.
    ## should inherit from Auth::Notifier.
    ## the class used to send the notification
    attr_accessor :mailer_class
     
    ## the queue adapter for the delayed jobs
    ## @used in OtpJob
    attr_accessor :queue_adapter

    attr_accessor :navbar

    

    def initialize
      

      ##############################################################
      ##
      ## CSS BASED OPTIONS.
      ##
      ##############################################################
      
      ## whether there should be modals for sign-in / sign-up
      ## ensure to include the css and js files as mentioned in the readme.
      @enable_sign_in_modals = false
      
      ## this is shown on the left hand side of the navbar.
      @brand_name = "Your App Name"

      ## whether there should be a navbar as shown in the image in the readme.
      @navbar = false

      #############################################################
      ##
      ## AUTHENTICATION OPTIONS.
      ##
      #############################################################
      
      ## whether token authentication should be enabled
      @enable_token_auth = true

      ##the regeneration time of the auth_token,
      ##after the following mentioned time, the token is useless
      @token_regeneration_time = 1.day

      ## the oauth provider details, an empty hash will disable oauth authentication
      @oauth_credentials = {}
      
      ## which models the engine should use for authentication
      @auth_resources = {}

      ## whether recaptcha should be enabled or not.
      ## false by default.
      ## if set to true, will produce errors all over the place in case you forget to provide a recaptcha key and secret in the configuration file!
      @recaptcha = false


      ##############################################################
      ##
      ## ENGINE BASED OPTIONS.
      ##
      ##############################################################
      @mount_path = "/authenticate"
      @redis_config_file_location = nil
      @third_party_api_keys = {}
      ##whether to redirect to redirect urls if provided in the
      ##request.
      @do_redirect = true;


      ###############################################################
      ##
      ## OPTIONS FOR TESTS
      ##
      ###############################################################
      @stub_otp_api_calls = false
      @simulate_invalid_otp = false

      ###############################################################
      ##
      ## OPTIONS FOR OTP
      ##
      ###############################################################
      @otp_controller = nil


      ###############################################################
      ##
      ## OPTIONS FOR SHOPPING MODULE
      ##
      ###############################################################
      @cart_item_controller = nil
      @cart_item_class = nil
      @cart_controller = nil
      @cart_class = nil
      @payment_controller = nil
      @payment_class = nil
      @payment_gateway_info = {}
        

      ###############################################################
      ##
      ## OPTIONS FOR MAILER AND NOTIFICATIONS
      ##
      ###############################################################
      @mailer_class = nil
      @notification_class = nil
      @notification_response_class = nil

      
      
      
      ###############################################################
      ##
      ## OPTIONS FOR THE BACKGROUND JOB USED BY THE ENGINE.
      ##
      ###############################################################
      @queue_adapter = "shoryuken"

     

    end
  end
  

end
