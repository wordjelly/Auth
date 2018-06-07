##here add the internal lib files or anything else that is going to be
##needed throughout the app, that was defined or created inside the app itself.
require "auth/omniauth/path"
require "auth/partials"
require "auth/rails/routes"
require "auth/two_factor_otp"
require "auth/mailgun"
require "auth/job_exception_handler"
require "auth/url_shortener"
require "auth/notify"
require "auth/search/main"
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
    attr_accessor :prevent_oauth_merger
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
    attr_accessor :product_class
    attr_accessor :product_controller
    attr_accessor :payment_class
    attr_accessor :discount_class
    attr_accessor :discount_controller
    attr_accessor :notification_class
    attr_accessor :payment_controller
    attr_accessor :payment_gateway_info
    attr_accessor :token_regeneration_time
    attr_accessor :user_class
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

    ## used in lib/auth/omniauth.rb
    ## inside Google_OAuth2.class_eval
    attr_accessor :host_name


    ## whether to use es or not.
    attr_accessor :use_es


    ########################################################
    ##
    ##
    ## workflow accessors.
    ##
    ##
    ########################################################
    attr_accessor :consumable_class
    attr_accessor :consumable_controller

    attr_accessor :assembly_class
    attr_accessor :assembly_controller

    attr_accessor :stage_class
    attr_accessor :stage_controller

    attr_accessor :sop_class
    attr_accessor :sop_controller

    attr_accessor :step_class
    attr_accessor :step_controller

    attr_accessor :order_class
    attr_accessor :order_controller

    attr_accessor :requirement_class
    attr_accessor :requirement_controller

    attr_accessor :state_class
    attr_accessor :state_controller

    ## this tlocation thing is no longer used.
    attr_accessor :tlocation_class
    attr_accessor :tlocation_controller

    ## CURRENTLY USED
    attr_accessor :location_class
    attr_accessor :location_controller

    ## these three are not used.
    attr_accessor :schedule_class
    attr_accessor :schedule_controller

    attr_accessor :booking_class
    attr_accessor :booking_controller

    attr_accessor :slot_class
    attr_accessor :slot_controller
    ## the above three are not used.

    ## this is also no longer user.
    attr_accessor :overlap_class
    attr_accessor :overlap_controller



    #######################################################
    ####        CURRENTLY USED                         ####

    attr_accessor :category_class
    attr_accessor :category_controller

    attr_accessor :minute_class
    attr_accessor :minute_controller

    attr_accessor :entity_class
    attr_accessor :entity_controller

    attr_accessor :specification_class
    attr_accessor :specification_controller
    ########################################################
    ##
    ##
    ##
    ## image concern accessors
    ##
    ##
    #######################################################

    attr_accessor :image_class
    attr_accessor :image_controller


    #######################################################
    ##
    ##
    ##
    ## WORK CONSTANTS.
    ##
    ##
    #######################################################

    attr_accessor :rolling_minutes

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


      ## if set to true, wil prevent merging of oauth accounts if they share the same email id.
      ## by default is false.
      @prevent_oauth_merger = false

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
      @do_redirect = true
      @host_name = nil
      ## for the user.
      @user_class = nil

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
      @product_class = nil
      @product_controller = nil
      @discount_class = nil
      @discount_controller = nil

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

      
      ####################################################
      ##
      ##
      ## elasticsearch options.
      ##
      ###################################################
      @use_es = true

      ########################################################
      ##
      ##
      ## workflow accessors.
      ##
      ## are set to default to the engine classes.
      ## so if you don't set them, it doesn't matter.
      ##
      ########################################################
      @assembly_class = "Auth::Workflow::Assembly"
      @assembly_controller = "auth/workflow/assemblies"

      @stage_class = "Auth::Workflow::Stage"
      @stage_controller = "auth/workflow/stages"

      @sop_class = "Auth::Workflow::Sop"
      @sop_controller = "auth/workflow/sops"

      @step_class = "Auth::Workflow::Step"
      @step_controller = "auth/workflow/steps"
        
      @order_class = "Auth::Workflow::Order"
      @order_controller = "auth/workflow/orders"

      @requirement_class = "Auth::Workflow::Requirement"
      @requirement_controller = "auth/workflow/requirements"  

      @state_class = "Auth::Workflow::State"
      @state_controller = "auth/workflow/states"

      ## tlocation is not used anywhere, either the model or controller
      @tlocation_class = "Auth::Workflow::Tlocation"
      @tlocation_controller = "auth/workflow/tlocations"

      
      @location_class = "Auth::Workflow::Location"
      @location_controller = "auth/workflow/locations"

      @schedule_class = "Auth::Workflow::Schedule"
      @schedule_controller = "auth/workflow/schedules"

      @booking_class = "Auth::Workflow::Booking"
      @booking_controller = "auth/workflow/bookings"

      @slot_class = "Auth::Workflow::Slot"
      @slot_controller = "auth/workflow/slots"

      @overlap_class = "Auth::Workflow::Overlap"
      @overlap_controller = "auth/workflow/overlaps"

      @minute_class = "Auth::Workflow::Minute"
      @minute_controller = "auth/workflow/minutes"

      @category_class = "Auth::Workflow::Category"
      @category_controller = "auth/workflow/categories"

      @entity_class = "Auth::Workflow::Entity"
      @entity_controller = "auth/workflow/entities"

      @specification_class = "Auth::Workflow::Specification"
      @specification_controller = "auth/workflow/specifications"

      ## this is the 
      @consumable_class = "Auth::Workflow::Consumable"
      @consumable_controller = "auth/workflow/consumables"
      ########################################################
      ##
      ##
      ##
      ## IMAGE CONCERN MODEL AND CONTROLLER CLASSES
      ##
      ##
      ##
      ########################################################

      @image_class = "Auth::Image"
      @image_controller = "auth/images"


      ########################################################
      ##
      ## ROLLING MINUTES
      ##
      ########################################################
      @rolling_minutes = 30

    end
  end
  

end
