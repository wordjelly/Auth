require 'mongoid'
require 'simple_token_authentication'


module Auth::Concerns::UserConcern
		
	

	extend ActiveSupport::Concern
	included do 

		##if devise modules are not defined, then define them, by default omniauth contains 
		unless self.method_defined?(:devise_modules)
	      devise :database_authenticatable, :registerable,
	          :recoverable, :trackable, :validatable, :confirmable
	      devise :omniauthable, :omniauth_providers => [:google_oauth2,:facebook]
	      ## Database authenticatable
		  field :email,              type: String, default: ""
		  field :encrypted_password, type: String, default: ""

		  ## Recoverable
		  field :reset_password_token,   type: String
		  field :reset_password_sent_at, type: Time

		  ## Rememberable
		  field :remember_created_at, type: Time

		  ## Trackable
		  field :sign_in_count,      type: Integer, default: 0
		  field :current_sign_in_at, type: Time
		  field :last_sign_in_at,    type: Time
		  field :current_sign_in_ip, type: String
		  field :last_sign_in_ip,    type: String

		  field :identities,          type: Array, default: [{"uid" => "", "provider" => "", "email" => ""}]
		  

		  ## Confirmable
		   field :confirmation_token,   type: String
		   field :confirmed_at,         type: Time
		   field :confirmation_sent_at, type: Time
		   field :unconfirmed_email,    type: String # Only if using reconfirmable

		  ## Lockable
		  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
		  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
		  # field :locked_at,       type: Time

	    end

	    unless Auth.configuration.enable_token_auth

	    else
	    	
	    	acts_as_token_authenticatable
  			field :authentication_token
	    	field :es
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



end