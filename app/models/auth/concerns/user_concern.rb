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
		      devise :validatable
		      devise :trackable
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
		 	  field :access_token,        type: String
		 	  field :token_expires_at,	  type: Integer
		 	  field :token_expired,		  type: Boolean
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


	##FOR GETTING INFORMATION FROM THIRDY PARTY OAUTH PROVIDERS.
	def get_info_from_oauth_provider
		##this is where we can set the token_expired flag easily
		
	end


	
	def as_json(options)
		 if !self.current_app_id.nil?
		 	json = super(:only => [:authentication_token])
	     	json[:es] = self.client_authentication[self.current_app_id]
	     	##resetting this before returning the json value.
	     	self.current_app_id = nil
	    	json
	 	 else
	 	 	nil
	 	 end
	end

	##returns true if there is at least one non empty oauth identity
	def has_oauth_identity?
		return unless self.respond_to? :identities
		self.identities.keep_if{|c| Auth::Identity.new(c).has_provider?}.size > 0
	end

end