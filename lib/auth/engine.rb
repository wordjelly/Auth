##here add the internal lib files or anything else that is going to be
##needed throughout the app, that was defined or created inside the app itself.
require "auth/omniauth/path"
require "auth/rails/routes"
require "auth/two_factor_otp"
require "auth/job_exception_handler.rb"

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

    def initialize
      @enable_token_auth = true
      @oauth_credentials = {}
      @mount_path = "/authenticate"
      @auth_resources = {}
      @enable_sign_in_modals = true
      @recaptcha = true
      @redis_config_file_location = nil
      @third_party_api_keys = {}
      @stub_otp_api_calls = false
    end
  end
  

end
