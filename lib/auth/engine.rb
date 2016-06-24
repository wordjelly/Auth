require "auth/omniauth/path"
require "auth/rails/routes"
module Auth
  class Engine < ::Rails::Engine
    isolate_namespace Auth
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :enable_token_auth
    attr_accessor :oauth_credentials
    attr_accessor :mount_path
    attr_accessor :auth_resources
   

    def initialize
      
      @enable_token_auth = true
      @oauth_credentials = {}
      @mount_path = "/authenticate"
      @auth_resources = {}
    end
  end
  

end
