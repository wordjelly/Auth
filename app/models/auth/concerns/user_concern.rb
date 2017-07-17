require 'mongoid'
require 'simple_token_authentication'

module Auth::Concerns::UserConcern
		
	extend ActiveSupport::Concern

	included do 

		USER_INFO_FIELDS = ["name","image_url"]

		include MongoidVersionedAtomic::VAtomic
		##if devise modules are not defined, then define them, by default omniauth contains 
		
		after_save :create_client, :if => Proc.new { |a| (!(a.respond_to? :confirmed_at)) || (a.confirmed_at_changed?) }

		after_destroy :destroy_client

		##BASIC USER FIELDS.
		field :email, 				type: String, default: ""
		attr_accessor :skip_email_unique_validation
		field :login,				type: String

		

		##additional parameter by which login can be done.
		##it should be defined in the configuration.
		##see spec/dummy/config/initializers/preinitializer.rb		
		field :additional_login_param, 				type: String

		field :name,				type: String, default: ""
		field :image_url,			type: String, default: ""
		###ENDS.

		unless self.method_defined?(:devise_modules)

		  ##get the options for the current class.
		  opts = Auth.configuration.auth_resources[self.name]

		  ## Database authenticatable
	      ##
	      #################################
	      if !opts[:skip].include? :sessions
		      devise :database_authenticatable
		      devise :trackable
		      ##setting the authentication keys parameter here.
		      devise :authentication_keys => {:login => true}
			  field :encrypted_password, type: String, default: ""
			  field :client_id, type: BSON::ObjectId
			  field :sign_in_count,      type: Integer, default: 0
			  field :current_sign_in_at, type: Time
			  field :last_sign_in_at,    type: Time
			  field :current_sign_in_ip, type: String
			  field :last_sign_in_ip,    type: String
		  end
		  


		  ##REGISTRABLES
		  ##
		  ####################################
		  if !opts[:skip].include? :registrations
	      	devise :registerable
	      	devise :validatable
	      	##add some validations for additional_login_param
	      	validate :additional_login_param_val
	        field :remember_created_at, type: Time
	  	  end


	      ##### Recoverable
	      ###
	      ##########################################
	      if !opts[:skip].include? :passwords
		      devise :recoverable	      
			  field :reset_password_token,   type: String
			  field :reset_password_sent_at, type: Time
		  end

			      
	      
		  ##### ## Confirmable
		  ##
		  #########################################
		  if !opts[:skip].include? :confirmations
		      devise :confirmable
			  field :confirmation_token,   type: String
			  field :confirmed_at,         type: Time
			  field :confirmation_sent_at, type: Time
			  field :unconfirmed_email,    type: String # Only if using reconfirmable
	      end


		  ## Lockable
		  ###################
		  ##########################################
	      if !opts[:skip].include? :unlocks
		      devise :lockable
			  field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
			  field :unlock_token,    type: String # Only if unlock strategy is :email or :both
			  field :locked_at,       type: Time
	      end


	      ####OAUTHABLE
	      ##
	      ############################################3
	      if !opts[:skip].include? :omniauthable
		      devise :omniauthable, :omniauth_providers => [:google_oauth2,:facebook]
			  field :identities,          type: Array, default: [Auth::Identity.new.attributes.except("_id")]
		  end

		  
		  

	    end

	    unless Auth.configuration.enable_token_auth
	    	
	    else
	    	
	    	acts_as_token_authenticatable
  			field :authentication_token, type: String
	    	field :client_authentication, type: Hash, default: {}
	    	field :current_app_id, type: String
	    	

	    end

	end

	##FOR THE LOGIN AUTHENTICATION KEY PARAMETER, WE DEFINE GETTERS AND SETTERS
	def login=(login)
		@login = login
	end

	def login
		 @login || self.email || self.additional_login_param
	end


	##reset the auth token if the email or password changes.
	def email=(email)
		super
		reset_token
	end

	def password=(password)
		super
		reset_token
	end


	def reset_token
		self.authentication_token = nil
	end

	#def has_token_and_es
	#	return !self.authentication_token.nil?
	#end

	

	##setting these as nil, forces a new auth_token and es to be generated
	##because in the before_save hooks they are set if they are blank.
	#def set_es
	#    if !email.nil?
	#      salt = SecureRandom.hex(32)
	#      pre_es = salt + email
	#      self.es = Digest::SHA256.hexdigest(pre_es)
	#    end
	#end

	def set_client_authentication(app_id)
		if self.client_authentication[app_id].nil? && self.valid?
			self.client_authentication[app_id] = SecureRandom.hex(32)
			
			self.save
		end
		self.current_app_id = app_id
	end


	def destroy_client
		@client = Auth::Client.find(self.id)
		@client.delete
	end

	##tries to create a client with a unique api_key, and user id.
	##tries 10 attempts
	##initially tries a versioned_create
	##if the op is successfull then it breaks.
	##if the op_count becomes zero it breaks.
	##if there is no client with this user id, then and only then will it change the api_key and again try to create a client with this resource_id and this api_key.
	##at the end it will exit, and there may or may not be a client with this resource_id.
	##so this method basically fails silently, and so when you look at a user profiel and if you don't see an api_key, it means that there is no client for him, that is the true sign that it failed.
	##api key checking includes whether the user for that key is confirmed or not.
	##client is created irrespective of whether the user is confirmed or not.
	def create_client
		

		##we want to create a new client, provided that there is no client for this user id.
		##if a client already exists, then we dont want to do anything.
		##when we create the client we want to be sure that 
		##provided that there is no client with this user id.
		#puts "called create client."

		##first find out if there is already a client for this user id.
		c = Auth::Client.new(:api_key => SecureRandom.hex(32), :resource_id => self.id)


		c.versioned_create({:resource_id => self.id})
		op_count = 10

		

		while(true)
			
			if c.op_success?
				break
			elsif op_count == 0
				break
			elsif (Auth::Client.where(:resource_id => self.id).count == 0)
				c.api_key = SecureRandom.hex(32)
				c.versioned_create({:resource_id => self.id})
				op_count-=1
			else
				break
			end


		end

	end

	###@param[Array] : array of field names that you want the values for.
	###@return[Hash] : hash of key , value pairs containing the values that you asked for.
	def get_user_info(keys)
		keys = keys.keep_if{ |c| (USER_INFO_FIELDS.include? c) && (self.respond_to(c.to_sym)) }

		return Hash[keys.map{|c| [c,self.send("#{c}")]}]
	end


	

	
	def as_json(options)
		 if !self.current_app_id.nil?
		 	json = super(:only => [:authentication_token])
	     	json[:es] = self.client_authentication[self.current_app_id]
	     	##resetting this before returning the json value.
	     	self.current_app_id = nil
	    	json
	 	 else
	 	 	puts "returning nil from json."
	 	 	nil
	 	 end
	end

	##returns true if there is at least one non empty oauth identity
	def has_oauth_identity?
		return unless self.respond_to? :identities
		self.identities.keep_if{|c| Auth::Identity.new(c).has_provider?}.size > 0
	end

	## skip_email_unique_validation is set to true in omni_concern in the situation:
	##1.there is no user with the given identity.
	## however it is possible that a user with this email exists.
	## in that case, if we try to do versioned_create, then the prepare_insert block in mongoid_versioned_atomic, runs validations. these include, checking if the email is unique, and in this case, if a user with this email already exists, then the versioned_create doesnt happen at all. We don't want to first check if there is already an account with this email, and in another step then try to do a versioned_update, because in the time in between another user could be created. So instead we simply just set #skip_email_unique_validation to true, and as a result the unique validation is skipped.
	def email_changed?
    	super && skip_email_unique_validation.nil?
	end

	##if the additional login param key is enabled, and the additional login param has been provided in the params, then it will not validate for the presence of the email.
	##otherwise it will validate for the presence of the email.
	def email_required?
		(additional_login_param_enabled? && additional_login_param_provided?) ? false : true
	end

	##@return[Boolean] : true if the Auth.config has :additional_login_param in the :login_params key for this resource, and additional_login_param_name key is also present. 
	def additional_login_param_enabled?
		Auth.configuration.auth_resources[self.name][:login_params].include? :additional_login_param && !Auth.configuration.auth_resources[self.name][:additional_login_param_name].nil?
	end

	##@return[Boolean] : true if the params have a additional_login_param that is not nil.
	def additional_login_param_provided?
		!self.additional_login_param.nil?
	end


	def additional_login_param_val

	end


end