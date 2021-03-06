$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "auth/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "wordjelly-auth"
  s.version     = Auth::VERSION
  s.authors     = ["bhargav"]
  s.email       = ["bhargav.r.raut@gmail.com"]
  s.homepage    = "http://github.com/wordjelly/auth"
  s.summary     = "Authentication engine, bundles mongoid, devise, and token authentication"
  s.description = "Simple authentication solution for any rails app."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "xpath", "2.1.0"
  s.add_dependency "rails", "~> 4.2.6"
  s.add_dependency "sass-rails"
  s.add_dependency "turbolinks"
  s.add_dependency "remotipart"
  s.add_dependency 'momentjs-rails'
  s.add_dependency 'simple_token_authentication', '~> 1.0'
  s.add_dependency 'devise', "4.1.1"
  s.add_dependency 'omniauth', '1.4.1'
  s.add_dependency 'omniauth-google-oauth2', '0.4.1'
  s.add_dependency 'omniauth-twitter'
  s.add_dependency 'omniauth-facebook', '4.0.0'
  s.add_dependency 'omniauth-linkedin'
  #s.add_dependency 'thin'
  s.add_dependency 'valid_url'
  s.add_dependency 'materialize-sass', '0.97.1'
  s.add_dependency 'recaptcha'
  s.add_dependency 'underscore-rails'
  s.add_dependency 'hashie','3.5.1'
  s.add_dependency 'typhoeus'
  s.add_dependency 'redis','3.3.1'
  s.add_dependency 'i18n','0.8.1'
  s.add_dependency 'kaminari-mongoid'
  s.add_dependency 'kaminari-actionview'
  s.add_dependency 'googl'
  #s.add_dependency 'premailer-rails'
  s.add_dependency 'sinatra'
  s.add_dependency 'dotenv-rails'
  s.add_dependency 'mongoid_versioned_atomic', '0.0.9'
  s.add_dependency 'wj-jquery-rails', '>= 4.2.2.1'
  s.add_dependency 'wj-mailgun-ruby', '>= 1.1.7'
  s.add_dependency 'wj-payuindia', '>= 0.1.1'
  s.add_dependency 'wj-mongoid-elasticsearch', '~> 0.0.1'
  s.add_dependency 'cloudinary'
  s.add_dependency 'mongoid-geospatial'
  s.add_dependency 'mongoid-embedded-errors'
  s.add_dependency 'delayed_job_mongoid'
  s.add_dependency 'daemons'
  #s.add_dependency 'mongoid-embedded-errors'
  s.add_development_dependency 'picasa'
  s.add_development_dependency 'puma'
  s.add_development_dependency 'faker'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'capybara-webkit', '1.14.0'
  s.add_development_dependency 'factory_girl_rails'
end
