# Use this hook to configure devise mailer, warden hooks and so forth.
# Many of these configuration options can be set straight in your model.
puts "-------------------------------------------------------------------------------------"
Devise.setup do |config|
  #parent controller
  config.parent_controller = 'Auth::ApplicationController'
  # The secret key used by Devise. Devise uses this key to generate
  # random tokens. Changing this key will render invalid all existing
  # confirmation, reset password and unlock tokens in the database.
  # Devise will use the `secret_key_base` as its `secret_key`
  # by default. You can change it below and use your own secret key.
  # config.secret_key = 'a66b3c69092bb2bfb7364f6140a0874e128da2893d8730f1f646eca560ef84cc32f6a40605d24f56a044b216b73483201b72c28a82c487109b885f812efff607'

  # ==> Mailer Configuration
  # Configure the e-mail address which will be shown in Devise::Mailer,
  # note that it will be overwritten if you use your own mailer class
  # with default "from" parameter.
  config.mailer_sender = 'hi_there_i_come_from_the_engine@gmail.com'

  # Configure the class responsible to send e-mails.
  # config.mailer = 'Devise::Mailer'

  # Configure the parent class responsible to send e-mails.
  # config.parent_mailer = 'ActionMailer::Base'

  # ==> ORM configuration
  # Load and configure the ORM. Supports :active_record (default) and
  # :mongoid (bson_ext recommended) by default. Other ORMs may be
  # available as additional gems.
  require 'devise/orm/mongoid'

  # ==> Configuration for any authentication mechanism
  # Configure which keys are used when authenticating a user. The default is
  # just :email. You can configure it to use [:username, :subdomain], so for
  # authenticating a user, both parameters are required. Remember that those
  # parameters are used only when authenticating and not when retrieving from
  # session. If you need permissions, you should implement that in a before filter.
  # You can also supply a hash where the value is a boolean determining whether
  # or not authentication should be aborted when the value is not present.
  #config.authentication_keys = [:email]

  # Configure parameters from the request object used for authentication. Each entry
  # given should be a request method and it will automatically be passed to the
  # find_for_authentication method and considered in your model lookup. For instance,
  # if you set :request_keys to [:subdomain], :subdomain will be used on authentication.
  # The same considerations mentioned for authentication_keys also apply to request_keys.
  # config.request_keys = []

  # Configure which authentication keys should be case-insensitive.
  # These keys will be downcased upon creating or modifying a user and when used
  # to authenticate or find a user. Default is :email.
  config.case_insensitive_keys = [:email]

  # Configure which authentication keys should have whitespace stripped.
  # These keys will have whitespace before and after removed upon creating or
  # modifying a user and when used to authenticate or find a user. Default is :email.
  config.strip_whitespace_keys = [:email]

  # Tell if authentication through request.params is enabled. True by default.
  # It can be set to an array that will enable params authentication only for the
  # given strategies, for example, `config.params_authenticatable = [:database]` will
  # enable it only for database (email + password) authentication.
  # config.params_authenticatable = true

  # Tell if authentication through HTTP Auth is enabled. False by default.
  # It can be set to an array that will enable http authentication only for the
  # given strategies, for example, `config.http_authenticatable = [:database]` will
  # enable it only for database authentication. The supported strategies are:
  # :database      = Support basic authentication with authentication key + password
  # config.http_authenticatable = false

  # If 401 status code should be returned for AJAX requests. True by default.
  # config.http_authenticatable_on_xhr = true

  # The realm used in Http Basic Authentication. 'Application' by default.
  # config.http_authentication_realm = 'Application'

  # It will change confirmation, password recovery and other workflows
  # to behave the same regardless if the e-mail provided was right or wrong.
  # Does not affect registerable.
  # config.paranoid = true

  # By default Devise will store the user in session. You can skip storage for
  # particular strategies by setting this option.
  # Notice that if you are skipping storage for all authentication paths, you
  # may want to disable generating routes to Devise's sessions controller by
  # passing skip: :sessions to `devise_for` in your config/routes.rb
  config.skip_session_storage = [:http_auth]

  # By default, Devise cleans up the CSRF token on authentication to
  # avoid CSRF token fixation attacks. This means that, when using AJAX
  # requests for sign in and sign up, you need to get a new CSRF token
  # from the server. You can disable this option at your own risk.
  # config.clean_up_csrf_token_on_authentication = true

  # ==> Configuration for :database_authenticatable
  # For bcrypt, this is the cost for hashing the password and defaults to 11. If
  # using other algorithms, it sets how many times you want the password to be hashed.
  #
  # Limiting the stretches to just one in testing will increase the performance of
  # your test suite dramatically. However, it is STRONGLY RECOMMENDED to not use
  # a value less than 10 in other environments. Note that, for bcrypt (the default
  # algorithm), the cost increases exponentially with the number of stretches (e.g.
  # a value of 20 is already extremely slow: approx. 60 seconds for 1 calculation).
  config.stretches = Rails.env.test? ? 1 : 11

  # Set up a pepper to generate the hashed password.
  config.pepper = '237ce91cd770ea7189d69556aba568168d963ada7b3782b56a581711c7675453168cb3ad0302955f86d9d2552e1ef4e964ba95a0bfa4d29cfe1e55094294b7a8'

  # Send a notification email when the user's password is changed
  # config.send_password_change_notification = false

  # ==> Configuration for :confirmable
  # A period that the user is allowed to access the website even without
  # confirming their account. For instance, if set to 2.days, the user will be
  # able to access the website for two days without confirming their account,
  # access will be blocked just in the third day. Default is 0.days, meaning
  # the user cannot access the website without confirming their account.
  # config.allow_unconfirmed_access_for = 2.days

  # A period that the user is allowed to confirm their account before their
  # token becomes invalid. For example, if set to 3.days, the user can confirm
  # their account within 3 days after the mail was sent, but on the fourth day
  # their account can't be confirmed with the token any more.
  # Default is nil, meaning there is no restriction on how long a user can take
  # before confirming their account.
  # config.confirm_within = 3.days

  # If true, requires any email changes to be confirmed (exactly the same way as
  # initial account confirmation) to be applied. Requires additional unconfirmed_email
  # db field (see migrations). Until confirmed, new email is stored in
  # unconfirmed_email column, and copied to email column on successful confirmation.
  config.reconfirmable = true

  # Defines which key will be used when confirming an account
  # config.confirmation_keys = [:email]

  # ==> Configuration for :rememberable
  # The time the user will be remembered without asking for credentials again.
  # config.remember_for = 2.weeks

  # Invalidates all the remember me tokens when the user signs out.
  config.expire_all_remember_me_on_sign_out = true

  # If true, extends the user's remember period when remembered via cookie.
  # config.extend_remember_period = false

  # Options to be passed to the created cookie. For instance, you can set
  # secure: true in order to force SSL only cookies.
  # config.rememberable_options = {}

  # ==> Configuration for :validatable
  # Range for password length.
  config.password_length = 6..128

  # Email regex used to validate email formats. It simply asserts that
  # one (and only one) @ exists in the given string. This is mainly
  # to give user feedback and not to assert the e-mail validity.
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # ==> Configuration for :timeoutable
  # The time you want to timeout the user session without activity. After this
  # time the user will be asked for credentials again. Default is 30 minutes.
  # config.timeout_in = 30.minutes

  # ==> Configuration for :lockable
  # Defines which strategy will be used to lock an account.
  # :failed_attempts = Locks an account after a number of failed attempts to sign in.
  # :none            = No lock strategy. You should handle locking by yourself.
  config.lock_strategy = :failed_attempts

  # Defines which key will be used when locking and unlocking an account
  config.unlock_keys = [:email]

  # Defines which strategy will be used to unlock an account.
  # :email = Sends an unlock link to the user email
  # :time  = Re-enables login after a certain amount of time (see :unlock_in below)
  # :both  = Enables both strategies
  # :none  = No unlock strategy. You should handle unlocking by yourself.
  config.unlock_strategy = :both

  # Number of authentication tries before locking an account if lock_strategy
  # is failed attempts.
  config.maximum_attempts = 20

  # Time interval to unlock the account if :time is enabled as unlock_strategy.
  config.unlock_in = 1.hour

  # Warn on the last attempt before the account is locked.
  # config.last_attempt_warning = true

  # ==> Configuration for :recoverable
  #
  # Defines which key will be used when recovering the password for an account
  config.reset_password_keys = [:email]

  # Time interval you can reset your password with a reset password key.
  # Don't put a too small interval or your users won't have the time to
  # change their passwords.
  config.reset_password_within = 6.hours

  # When set to false, does not sign a user in automatically after their password is
  # reset. Defaults to true, so a user is signed in automatically after a reset.
  # config.sign_in_after_reset_password = true

  # ==> Configuration for :encryptable
  # Allow you to use another hashing or encryption algorithm besides bcrypt (default).
  # You can use :sha1, :sha512 or algorithms from others authentication tools as
  # :clearance_sha1, :authlogic_sha512 (then you should set stretches above to 20
  # for default behavior) and :restful_authentication_sha1 (then you should set
  # stretches to 10, and copy REST_AUTH_SITE_KEY to pepper).
  #
  # Require the `devise-encryptable` gem when using anything other than bcrypt
  # config.encryptor = :sha512

  # ==> Scopes configuration
  # Turn scoped views on. Before rendering "sessions/new", it will first check for
  # "users/sessions/new". It's turned off by default because it's slower if you
  # are using only default views.
  # config.scoped_views = false

  # Configure the default scope given to Warden. By default it's the first
  # devise role declared in your routes (usually :user).
  # config.default_scope = :user

  # Set this configuration to false if you want /users/sign_out to sign out
  # only the current scope. By default, Devise signs out all scopes.
  # config.sign_out_all_scopes = true

  # ==> Navigation configuration
  # Lists the formats that should be treated as navigational. Formats like
  # :html, should redirect to the sign in page when the user does not have
  # access, but formats like :xml or :json, should return 401.
  #
  # If you have any extra navigational formats, like :iphone or :mobile, you
  # should add them to the navigational formats lists.
  #
  # The "*/*" below is required to match Internet Explorer requests.
  config.navigational_formats = ['*/*', :html, :json, :js]

  # The default HTTP method used to sign out a resource. Default is :delete.
  config.sign_out_via = :delete

  # ==> OmniAuth
  # Add a new OmniAuth provider. Check the wiki for more information on setting
  # up on your models and hooks.
  # config.omniauth :github, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'
  #config.omniauth :facebook, FACEBOOK_CREDENTIALS[0], FACEBOOK_CREDENTIALS[1],{
  # :scope => 'email',
  # :info_fields => 'first_name,last_name,email,work',
  #  :display => 'page'
  #}

  # ==> Warden configuration
  # If you want to use other strategies, that are not supported by Devise, or
  # change the failure app, you can configure them inside the config.warden block.
  #
   #config.warden do |manager|
     #manager.intercept_401 = false
     #manager.default_strategies(scope: :user).unshift :some_external_strategy
     #manager.failure_app = CustomFailure
   #end

  # ==> Mountable engine configurations
  # When using Devise inside an engine, let's call it `MyEngine`, and this engine
  # is mountable, there are some extra configurations to be taken into account.
  # The following options are available, assuming the engine is mounted as:
  #
  #     mount MyEngine, at: '/my_engine'
  #
  # The router that invoked `devise_for`, in the example above, would be:
  #config.router_name = :auth
  #
  # When using OmniAuth, Devise cannot automatically set OmniAuth path,
  # so you need to do it manually. For the users scope, it would be:
  #config.omniauth_path_prefix = '/other'
end



DeviseController.class_eval do 
  
  
  
  include Auth::Concerns::DeviseConcern  
  
  ##add to devise concern.
  skip_before_action :assert_is_devise_resource!, if: :is_omniauth_callback?

  

  def redirect_to(options = {}, response_status = {})

      cli = session[:client]
       if (session[:client] && (session[:client].is_a? Hash))
        cli = Auth::Client.new(session[:client])
       end
      ##this handles the condition for example where the user comes to the sign in page with a valid redirect url and api key, then goes to the oauth page, then he clicks sign in by oauth, and comes back from oauth provider after a valid sign in, what happens as a result is that the request variable @redirect_url which was set when the user came to the sign_in_page(or any page controlled by the devise controller), is knocked off, because of the visit to the other domain. But the session variable is still intact, so we set the request variable again to the session variable and everything in front of that is just like what we normally do with render
      
      ##THIS SHOULD NO LONGER HAPPEN, I DONT WANT ANYONE TO BE AABLE TO VISIT THE WORDJELLY PAGE WITH A REDIRECT URL AND 
      #if !session[:redirect_url].nil? && @redirect_url.nil?
      #   @redirect_url = session[:redirect_url]
      #   @client = Auth::Client.new(session[:client])
      #end
      #super
      #puts "redirect url was : #{@redirect_url}"
      #puts "client was: #{@client}"
       
       #if options =~ /authentication_token|es/
        ##this situation is to prevnet re-redirects.
       # puts "detected auth token and es."
        #redirect_to(options,response_status)
       # super
      #end    

      ##HAVE NO IDEA WHAT THIS IS , AT THE MOMENT.
      if options =~ /authentication_token|es/
        ##this situation is to prevnet re-redirects.
       
        #redirect_to(options,response_status)
        super(options,response_status)
      else
        ##as long as its not destroy.
        #if resource && resource.set_client_authentication?(action_name,controller_name,cli)
        #  resource.set_client_authentication(cli)
        #end
        if (["passwords","confirmations","unlocks"].include? controller_name)
          super(options,response_status)
        else
          
          ##we have a redirect url
          ##we have a client authentication for the client.
          ##we have an authentication token
          ##we are signed_in
          ##we have at least one authentication_key confirmed.

          if resource && resource.reply_with_redirect_url_and_auth_token_and_es?(session[:redirect_url],cli,current_resource(resource))

            curr_app_es = resource.client_authentication[cli.current_app_id]
            session.delete(:client)
            
           
            redirect_to session.delete(:redirect_url) + "?authentication_token=" + resource.authentication_token + "&es=" + curr_app_es 
          else
            super
          end
        end
      end
  end
 
  def render(*args)

       cli = session[:client]
       if (session[:client] && (session[:client].is_a? Hash))
        cli = Auth::Client.new(session[:client])
       end


       #if resource && resource.set_client_authentication?(action_name,controller_name,cli)
       #  resource.set_client_authentication(cli)
       #end
   
        if (["passwords","confirmations","unlocks"].include? controller_name)
            super(*args)
        else
           
            if resource && resource.reply_with_redirect_url_and_auth_token_and_es?(session[:redirect_url],cli,current_resource(resource))

              curr_app_es = resource.client_authentication[cli.current_app_id]
              session.delete(:client)
              
              
              redirect_to (session.delete(:redirect_url) + "?authentication_token=" + resource.authentication_token + "&es=" + curr_app_es) 
            else
             
              super(*args)
            end
        end     
  end

  

  ##add to devise_concern.
  def require_no_authentication
    
    do_before_request
    #puts "came past do before request."

    assert_is_devise_resource!
    #puts "came past assert is devise resource"
    

    return unless is_navigational_format?

    #puts "came past is navigational format."

    no_input = devise_mapping.no_input_strategies
    #puts "no input is: #{no_input}"
   

    authenticated = if no_input.present?
      args = no_input.dup.push scope: resource_name
      #puts "authenticated already."
      warden.authenticate?(*args)
    else
      #puts "check if authenticated"
      warden.authenticated?(resource_name)
    end


    if authenticated && resource = warden.user(resource_name)
      if @redirect_url.nil?
        #puts "came to failure."
        flash[:alert] = I18n.t("devise.failure.already_authenticated")
        redirect_to after_sign_in_path_for(resource)
      else
        
      end
    end
  end

end

module Devise

  ##THIS CHANGE NEEDS TO BE MADE, IN ORDER TO CHANGE THE EMAIL_REQUIRED?
  ##PROTECTED METHOD FROM THE VALIDATABLE MODULE IN DEVISE.
  ##EMAIL IS REQUIRED ONLY IF THE ADDITIONAL LOGIN PARAM IS enabled , but still nil
  module Controllers
    module Helpers
      ##takes care of the test case where no devise mapping is specified in the request.env.
      ##as a result any method that is fired using this as a filter will not fire.
      ##in this case in dummy/ApplicationController.rb, we were configuring_permitted_params if it was a devise_controller.
      ##now this method is modified to first check if there is a devise_mapping, otherwise returns false.
      ## ref test: omniauth_callbacks_request_spec.rb #NO RESOURCE TEST
      def devise_controller?
        if request.env["devise.mapping"].nil?
          false
        else
          is_a?(::DeviseController)
        end
      end
    end
  end


  

  SessionsController.class_eval do 

    prepend_before_action :ignore_json_request, only: [:new]

    private
    ##if the destory request is json, we return not servicable.
    ##otherwise we do nothing.
    def verify_signed_out_user
      if is_json_request?
        render :nothing => true, :status => 406 and return
      end
      if all_signed_out?
        set_flash_message! :notice, :already_signed_out
        respond_to_on_destroy
      end
    end

  end

  PasswordsController.class_eval do 

    prepend_before_action :ignore_json_request, only: [:new]
    prepend_before_action :do_before_request, only: [:show,:create]


  end


  ##the solution to this problem is to change the html unlocks and confirmations "new" views
  ##here if it comes to this point, then 
  UnlocksController.class_eval do 

    prepend_before_action :ignore_json_request, only: [:new]
    prepend_before_action :do_before_request, only: [:show,:create]


    def show
     
      self.resource = resource_class.unlock_access_by_token(params[:unlock_token])
        
      yield resource if block_given?

      if resource.errors.empty?
        if is_json_request?
          render :nothing => true, :status => 201 and return 
        end
        set_flash_message! :notice, :unlocked
        respond_with_navigational(resource){ redirect_to after_unlock_path_for(resource) }
      else
        respond_with_navigational(resource.errors, status: :unprocessable_entity){ render :new }
      end
    end

  end



  ConfirmationsController.class_eval do 

    prepend_before_action :ignore_json_request, only: [:new]
    prepend_before_action :do_before_request, only: [:show,:create]


    def show
      self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      
      yield resource if block_given?

      if resource.errors.empty?
        set_flash_message!(:notice, :confirmed)
        if is_json_request?
          render :nothing => true, :status => 201 and return 
        else
          ##when we have first signed into the accoutn, and then we want to change the email, then when we click the confirmation link for the new email, in that case, we cannot set the resource to nil, since the user is already signed in, so we do this check to see if who we have signed in , is the same as the user who has confirmed, and in that case, we just let things proceed.
          current_resource = self.send("current_#{self.resource.class.name.downcase.to_s}")
          
          if current_resource && (current_resource.id.to_s == self.resource.id.to_s)

          else
            ## do this to force sign in after successfull confirmation

            self.resource = nil
          end
          respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
        end
      else
        respond_with_navigational(resource.errors, status: :unprocessable_entity){ render :new }
      end
    end
    

  end


  module Models

    module Recoverable

      ## change password instructions should not be sent if the user has oauth identities.
      def send_reset_password_instructions
        return if has_oauth_identity?
        token = set_reset_password_token
        send_reset_password_instructions_notification(token)
        token
      end

    end

  end

  
  module OmniAuth
    module UrlHelpers
      def omniauth_authorize_path(resource_or_scope, provider, *args)
        "#{request.base_url}#{Auth::OmniAuth::Path.omniauth_request_path(resource_or_scope,provider)}"
      end

      def omniauth_failure_path_for(resource_or_scope)
        "#{request.base_url}#{Auth::OmniAuth::Path.omniauth_failure_route_path(resource_or_scope)}"
      end
    end
  end




  Devise.include_helpers(Devise::OmniAuth)


  ##checks if the request is json, otherwise lets it fall back to whatever is defined by the custom_failure defined in the target app.
  ##if it is a json request, then renders a 401.
  class FailureApp  

    def self.call(env)
      @json_respond  ||= action(:json_respond)
      jf = @json_respond.call(env)
      if jf[0] == 401
        jf
      else
        @respond ||= action(:respond)
        @respond.call(env)
      end
    end

    def json_respond
     
      if request.format == :json or request.content_type == 'application/json'
            return json_failure
      end
      
    end

    def json_failure
        
        self.status = 401
        self.content_type = 'application/json'
        self.response_body = {"success"=> false, "errors" => ["u shall not pass LOL"]}.to_json
    end

    

  end

  ##the additional_login_param is added as a authentication_key 
  class ParameterSanitizer
    DEFAULT_PERMITTED_ATTRIBUTES =
      {
        sign_in: [:login,:password, :remember_me, :redirect_url, :api_key, :current_app_id],
        sign_up: [:password, :password_confirmation, :redirect_url, :api_key, :current_app_id],
        account_update: [:password, :password_confirmation, :current_password, :redirect_url, :api_key, :current_app_id]
      }

  end

end

