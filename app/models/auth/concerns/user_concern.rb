require 'mongoid'
require 'simple_token_authentication'


module Auth::Concerns::UserConcern
		
	extend ActiveSupport::Concern

	included do 


		include MongoidVersionedAtomic::VAtomic
		##if devise modules are not defined, then define them, by default omniauth contains 
		
		after_save :create_client


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
			  field :email,              type: String, default: ""
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
		      #devise :confirmable
			  #field :confirmation_token,   type: String
			  #field :confirmed_at,         type: Time
			  #field :confirmation_sent_at, type: Time
			  #field :unconfirmed_email,    type: String # Only if using reconfirmable
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
			  field :identities,          type: Array, default: [{"uid" => "", "provider" => "", "email" => ""}]
		  end

		  
		  

	    end

	    unless Auth.configuration.enable_token_auth
	    	
	    else
	    	
	    	acts_as_token_authenticatable
  			field :authentication_token, type: String
	    	field :es, type: String
	    	before_save do |document|
	    		
	    		if document.es.blank?
	    			
	    			document.set_es
	    		end
	    	end
	    end

	end

	

	def reset_token_and_es
		self.authentication_token = nil
		self.es = nil
	end

	def has_token_and_es
		return !self.es.nil? && !self.authentication_token.nil?
	end

	protected

	##setting these as nil, forces a new auth_token and es to be generated
	##because in the before_save hooks they are set if they are blank.
	

	def set_es
		
	    if !email.nil?
	      salt = SecureRandom.hex(32)
	      pre_es = salt + email
	      self.es = Digest::SHA256.hexdigest(pre_es)
	    end
		
	end

	##tries to create a client with a unique api_key, and user id.
	##tries 10 attempts
	##initially tries a versioned_create
	##if the op is successfull then it breaks.
	##if the op_count becomes zero it breaks.
	##if there is no client with this user id, then and only then will it change the api_key and again try to create a client with this user_id and this api_key.
	##at the end it will exit, and there may or may not be a client with this user_id.
	##so this method basically fails silently, and so when you look at a user profiel and if you don't see an api_key, it means that there is no client for him, that is the true sign that it failed.
	def create_client
		
		##we want to create a new client, provided that there is no client for this user id.
		##if a client already exists, then we dont want to do anything.
		##when we create the client we want to be sure that 
		##provided that there is no client with this user id.

		c = Auth::Client.new(:api_key => SecureRandom.hex(32), :user_id => self.id)

		c.versioned_create({:user_id => id, :api_key => c.api_key})
		op_count = 10

		while(true)

			if c.op_success?
				break
			elsif op_count == 0
				break
			elsif (Auth::Client.where(:user_id => id).count == 0)
				c.api_key = SecureRandom.hex(32)
				c.versioned_create({:user_id => id, :api_key => c.api_key})
				op_count-=1
			else
				break
			end

		end

		#puts "c op success was: #{c.op_success?}"


	end


end