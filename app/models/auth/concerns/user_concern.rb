require 'mongoid'
require 'simple_token_authentication'

module Auth::Concerns::UserConcern
		
	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	include Auth::Concerns::EsConcern

	included do 

		INDEX_DEFINITION = {
				index_name: Auth.configuration.brand_name.downcase,
				index_options:  {
				        settings:  {
				    		index: Auth::Concerns::EsConcern::AUTOCOMPLETE_INDEX_SETTINGS
					    },
				        mappings: {
				          "document" => Auth::Concerns::EsConcern::AUTOCOMPLETE_INDEX_MAPPINGS
				    }
				}
			}
		## so now first let me change the mapping name, and also shift the as_indexed_json def to the respective model everywhere


		include GlobalID::Identification

		USER_INFO_FIELDS = ["name","image_url"]

		PUBLICLY_VISIBLE_FIELD_NAMES = ["email","additional_login_param"]

		include MongoidVersionedAtomic::VAtomic
		

		opts = Auth.configuration.auth_resources[self.name]

		
		## so if it doesnt respond to confirmed_at -> then create a client anyways
		## if it responds to and the confirmed_at has changed, then create a client.
		after_save :create_client, :if => Proc.new { |a| (!(a.respond_to? :confirmed_at)) || (a.confirmed_at_changed?) || (a.additional_login_param_status_changed? && a.additional_login_param_status == 2) }
		#after_save :create_client

		after_save :set_client_authentication

		before_save do |document|
			## set the document resource id if its not already set.
			document.resource_id = document.id.to_s unless document.resource_id
			document.resource_class = document.class.name.to_s unless document.resource_class

			##if the additional login param changes, for eg. during an update, then set the additional login param status to pending immediately before saving itself, so that it is transactional type of thing.
			if document.additional_login_param_changed? && !document.additional_login_param.blank?
				document.additional_login_param_status = 1
			end

			if document.email_changed? || document.additional_login_param_changed? || document.encrypted_password_changed?
				document.regenerate_token
			end
		end

		after_destroy :destroy_client

		## if a or b or c.
		after_save :send_reset_password_link
			

		before_save :refresh_endpoints
		#######################################################
		#
		#
		# FIELDS FOR WORK 
		#
		#
		#######################################################

		field :cycle_types, type: Hash

		

		#######################################################
		#
		#
		# Owner concern is not included in user concern.
		# but we add the field "resource_id", because it allows
		# search in elasticsearch, for a user to find his own  record.
		#
		#######################################################

		field :resource_id, type: String
		field :resource_class, type: String


		########################################################
		# FIELDS FOR ALLOWING THE ADMIN TO CREATE USERS, AND ALSO REQUEST 
		#
		#
		#
		########################################################
		field :created_by_admin, type: Boolean, default: false

		



		########################################################
		##
		##
		##BASIC USER FIELDS.
		##
		##
		########################################################
		field :email, 				type: String
		attr_accessor :skip_email_unique_validation
		field :login,				type: String
		
		field :admin,				type: Boolean, default: false

		## the only way to set this is from the mongo console.
		## executive admin can do the actions like setting other admins as workers etc.
		field :chief_admin,		type: Boolean, default: false

		attr_accessor :m_client

		##additional parameter by which login can be done.
		##it should be defined in the configuration.
		##see spec/dummy/config/initializers/preinitializer.rb		
		field :additional_login_param, 				type: String
		
		##three possibilities
		##"pending" 1
		##"confirmed" 2
		##"unconfirmed" 0 
		field :additional_login_param_status,	type: Integer, default: 0
		
		
		
		field :name,				type: String, default: ""
		field :image_url,			type: String, default: ""
		###ENDS.

		unless self.method_defined?(:devise_modules)

		  ##get the options for the current class.
		  

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
	      	def email_required?
          		#additional_login_param.nil?
          		return additional_login_param.nil?
        	end 
	      	validates_presence_of   :additional_login_param, if: :additional_login_param_required?
	      	


	      	##IT ALLOWS A BLANK OR EMPTY ADDITIONAL LOGIN PARAM TO GO INTO THE DATABASE,BUT ONLY SENDS THE SMS_OTP IF THE PARAM IS NOT BLANK
	      	validates_uniqueness_of :additional_login_param, allow_blank: true, if: :additional_login_param_changed?
            
	        validate :additional_login_param_format, if: :additional_login_param_changed? 

	        ##VALIDATIONS TO BE DONE ONLY ON UPDATE
	        validate :additional_login_param_changed_on_unconfirmed_email,on: :update
	        validate :email_changed_on_unconfirmed_additional_login_param,on: :update
	        validate :email_and_additional_login_param_both_changed,on: [:update,:create]

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

			  ##this is what was overriden to ensure that confirmation_token and confirmation_sent_at are not set if we create an accoutn with just the mobile, but that caused active_for_authentication? to always return true, and so we had to let it be as is.
			  #def confirmation_required?
          	  #	!confirmed? && (self.email || self.unconfirmed_email)
        	  #end

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

		  	
		  ###############################################
		  ##
		  ## NOTIFICATION SUPPORT.
		  ##
		  ## this is permitted by default.
		  ## and i have to add this as an update feature.
		  ## that it adds the gcm_token 
		  ###############################################
		  field :android_token, type: String
		  field :android_endpoint, type: String
		  field :ios_token, type: String
		  field :ios_endpoint, type: String

		 

	    end

	    unless Auth.configuration.enable_token_auth
	    	
	    else
	    	
	    	acts_as_token_authenticatable
  			
  			## okay so this will be modified in the simple token authentication part.
  			attr_accessor :authentication_token
  			attr_accessor :es
  			field :encrypted_authentication_token, type: String

  			field :authentication_token_expires_at, type: Integer
	    	field :client_authentication, type: Hash, default: {}
	    	field :current_app_id, type: String
	    	

	    end

	    ##THIS METHOD HAD TO BE OVERRIDDEN TO FIND THE 
	    ##the user either by additional_login_param or email.
	    ##provide additional condition that the confirmed must be true.
	    def self.find_for_database_authentication(warden_conditions)
			
			conditions = warden_conditions.dup
			if login = conditions.delete(:login)
				login = login.downcase
		  		where(conditions).where('$or' => [ {:additional_login_param => /^#{Regexp.escape(login)}$/i, :additional_login_param_status => 2}, {:email => /^#{Regexp.escape(login)}$/i} ]).first
			else
				
		  		where(conditions).first
			end
  		end

  		
  		##override active_for_authentication? to say true if additional login param is confirmed.
		def active_for_authentication?
			#puts "came to active for authentication,"
			#puts "the status of additional login param is:"
			#puts additional_login_param_status.to_s
			##if additional_login_param is confirmed and 
			if additional_login_param_status == 2
				
				true
			else
				
				super
			end
		end 

		##this method takes the credential params which are expected to be something like:
		##{:email => "test", :resource => "authenticate/users"}
		##
		##basically it takes each of the login params defined in the
		##preinitializer for this resource, and then makes the conditions for all of them
		##for eg: if the login_params are "email,additional_login_param", then it will make the conditions look for both of them, for the same parameter that comes in .
		##conditions => [{"email" => "test"},{"additional_login_params" => "test"}]
		##these are then returned to the controller to be searched.
		def self.credential_exists(credential_params)
			login_params = Auth.configuration.auth_resources[self.name.to_s][:login_params]
			credential = credential_params.select{|c,v| login_params.include? c.to_sym}.values[0]
			conditions = login_params.map{|key|
				key = {key => credential}
			}
			conditions
		end 


				

	end

	module ClassMethods

		## @param[String] _id : the id sent into the request.
		## @param[Object] resource : the currently signed in resource.
		## how this works : it is called in the profiles_controller
		## if the current signed in resource is admin, then whatever user_id(_id) was requested is searched and returned.
		## if the current signed in resource is not admin, then _id is instead searched for using the current_signed_in_resource => basically will only return the user that is signed in.

		def find_resource(_id,resource)

			conditions = {:_id => _id}
			conditions[:_id] = resource.id.to_s if !resource.is_admin?
			all = self.where(conditions)
			
			return all.first if all.size > 0 
			return nil
		end

	end

	##FOR THE LOGIN AUTHENTICATION KEY PARAMETER, WE DEFINE GETTERS AND SETTERS
	def login=(login)
		@login = login
	end

	def login
		 @login || self.email || self.additional_login_param
	end

=begin
	##reset the auth token if the email or password changes.
	def email=(email)
		super
		#puts "email coming in is: #{email}"
		#puts "email set called."
		##method is defined in lib/omniauth#Simpletokenauthentication
		#if email_changed?
		regenerate_token
		#end
	end

	def additional_login_param=(additional_login_param)
		super
		
		regenerate_token
	end

	def password=(password)
		super
		
		regenerate_token
	end
=end

	

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

	def set_client_authentication
		

		if !self.m_client.nil?
			#puts "the client is not nil"
			#puts "is self client authentication nil"
			#puts self.client_authentication[self.m_client.current_app_id].nil?
			#puts "is self valie"
			#puts self.valid?
			if self.client_authentication[self.m_client.current_app_id].nil? && self.valid?
				self.client_authentication[self.m_client.current_app_id] = SecureRandom.hex(32)
				
				self.save
			end

		else
			
		end
		#
		
	end


	## @called_from : after_save -> override 
	## @working : 
	## if the resource was created by an administrator, and the attr_accessor request_send_reset_password_link is true, then it will check if the email is confirmed, and then send the reset_password_instructions to the email. otherwise will check if the mobile is confirmed, and will just generate that reset_password_link
	def send_reset_password_link
		
		reset_password_link = nil

		#puts "came to send reset password link, and this is the attr accessor."
		#puts self.request_send_reset_password_link.to_s

		## if there was an unconfirmed_email present.

		if self.created_by_admin

			#puts "the request send is true."
			#puts self.attributes.to_s
			#puts "is the additional login param confirmed"
			#puts self.additional_login_param_confirmed?
			## this case is exceptional because the user will have gone to 
			if self.confirmed?
				#puts "self is confirmed."
				begin
					self.class.skip_callback(:save, :after, :send_reset_password_link)
					
					self.class.send_reset_password_instructions(self.attributes)
				rescue
				ensure
					self.created_by_admin = false
					self.save
					self.class.set_callback(:save, :after, :send_reset_password_link)
				end

			elsif self.additional_login_param_confirmed?
				#puts "additiona login param is confirmed."
				begin
					#self.created_by_admin = false
					self.class.skip_callback(:save, :after, :send_reset_password_link)
					reset_password_link = Rails.application.routes.url_helpers.send("edit_#{self.class.name.downcase}_password_path",{:reset_password_token => self.set_reset_password_token})
						
				rescue => e
					puts e.to_s
				ensure
					self.created_by_admin = false
					self.save
					self.class.set_callback(:save, :after, :send_reset_password_link)
				end
				
			end

		end		
		
		reset_password_link

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
		
		#puts "self additional login param status changed ?"
		#puts self.additional_login_param_status_changed?
		#puts "self status is: #{self.additional_login_param_status}"
		##we want to create a new client, provided that there is no client for this user id.
		##if a client already exists, then we dont want to do anything.
		##when we create the client we want to be sure that 
		##provided that there is no client with this user id.
		#puts "called create client."

		##first find out if there is already a client for this user id.
		c = Auth::Client.new(:api_key => SecureRandom.hex(32), :resource_id => self.id)

		#puts "Came to create a client."

		c.versioned_create({:resource_id => self.id})
		op_count = 10

		#puts "-------CREATED A CLIENT AS FOLLOWS:-----------"
		#puts c.attributes.to_s

		while(true)
			
			if c.op_success?
				#puts "the op was a success"
				break
			elsif op_count == 0
				#puts "op count was 0"
				break
			elsif (Auth::Client.where(:resource_id => self.id).count == 0)
				#puts "tried to create here."
				c.api_key = SecureRandom.hex(32)
				c.versioned_create({:resource_id => self.id})
				op_count-=1
			else
				#puts "finally broke."
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

	



	

	##for the api responses.
	##if there is a current_app_id, then it will respond with the 
	##authentication-token and es
	##if there is none, then it will return nil.
	##it should return the errors irrespective of these settings.
	## if otp_verification key is present in the options, then the auth_token and es will not be returned.
	## this is needed in 
	def as_json(options={})
		
		## basically here the problem is that if the user himself is searching for his own record, then it is trying to return the authentication token.
		## 
		
		json = {:nothing => true}
		
		if (!self.destroyed? && options[:otp_verification].nil?)
			
			if self.m_client.current_app_id && at_least_one_authentication_key_confirmed? && self.errors.empty?
			 		
			 		json = {}
		     		json[:es] = self.client_authentication[self.m_client.current_app_id]
		     		json[:authentication_token] = self.	authentication_token

		     		unless options[:show_id].nil?
		     			json[:id] = self.id.to_s
		     			json[:admin] = self.admin.to_s
		     		end
		     	
		 	end
		 	if self.errors.full_messages.size > 0
		 	 	json[:errors] = self.errors.full_messages
		 	end
	 	end
	 	json
	end

	##returns true if there is at least one non empty oauth identity
	def has_oauth_identity?
		return false unless self.respond_to? :identities
		self.identities.keep_if{|c| 

			Auth::Identity.new(c).has_provider?

			}.size > 0
	end

	## skip_email_unique_validation is set to true in omni_concern in the situation:
	##1.there is no user with the given identity.
	## however it is possible that a user with this email exists.
	## in that case, if we try to do versioned_create, then the prepare_insert block in mongoid_versioned_atomic, runs validations. these include, checking if the email is unique, and in this case, if a user with this email already exists, then the versioned_create doesnt happen at all. We don't want to first check if there is already an account with this email, and in another step then try to do a versioned_update, because in the time in between another user could be created. So instead we simply just set #skip_email_unique_validation to true, and as a result the unique validation is skipped.
	def email_changed?
    	super && skip_email_unique_validation.nil?
	end


	##it is required only if the email is missing.
	def additional_login_param_required?
		email.nil?
	end

	##this method will validate the format of the additional_login_param.
	##it can be overridden by the user to do his own custom validation.
	##default behaviour is not to add any errors in the validation process.
	def additional_login_param_format
		
	end

	## confirmed?
	## OR 
	## both email and unconfirmed email are nil AND additional_login_param has been confirmed already.
	##currently used in this file in #authentication_keys_confirmed?
	def email_confirmed_or_does_not_exist
		(self.confirmed? && !self.pending_reconfirmation?)  ||  (self.email.nil? && self.unconfirmed_email.nil?)
	end

	def additional_login_param_confirmed?
		self.additional_login_param_status == 2 
	end

	## if the additional_login_param_status == 2
	def additional_login_param_confirmed_or_does_not_exist
		additional_login_param_confirmed? || self.additional_login_param_status == 0
	end
	
	## at least one authentication_key should be confirmed.
	## so even if we change the other one, we still return the remote authentication options even when that one is still unconfirmed.
	## used in lib/devise to decide whether to return the auth token and es and redirect.
	## used in self.as_json, to see whether to return the auth_token and es.
	def at_least_one_authentication_key_confirmed?
		(self.confirmed? && !self.pending_reconfirmation?) || self.additional_login_param_status == 2
	end

	## used in auth/registrations/update.js.erb
	## use it to chekc if the resource is fully confirmed, otherwise we redirect in the erb to whichever of the two needs to be confirmed.
	def authentication_keys_confirmed?	
		return email_confirmed_or_does_not_exist && additional_login_param_confirmed_or_does_not_exist
	end

	##if you change the additional login param while the email is not confirmed, you will get a validation error on additional_login_param
	def additional_login_param_changed_on_unconfirmed_email
		#puts "calling additional login param changed"
		#puts "pending reconfirmation?"
		#puts self.pending_reconfirmation?		

		if additional_login_param_changed?  && (self.pending_reconfirmation?)
			errors.add(:additional_login_param,"Please verify your email or add an email id before changing your #{additional_login_param_name}")
		end
	end

	##if you change the email while the additional login param not confirmed, then you will get validation errors on the email, as long as you have enabled an additional_login_param in the configuration.
	def email_changed_on_unconfirmed_additional_login_param
		#puts "calling email changed"
		if email_changed? && (additional_login_param_status == 1) && additional_login_param_name
			errors.add(:email, "Please add or verify your #{additional_login_param_name} before changing your email id")
		end
	end

	##has the attribute gone from blank to blank?
	##what happens is that if submit the update form, it submits empty strings for input fields which we dont fill. so suppose you change the adiditonal_login_param , it will submit email as "", in that case , earlier the email was nil, and now it becomes "", so that is detected as an email change and it feels like both email and additional param have changed and triggers the validation #email_and_additional_login_param_both_changed, so we dont want that to happen, so we check if the param has gone from being blank to blank in the below validation.
	##@param attr[String] : the param name.
	def attr_blank_to_blank?(attr)
		#puts "calling blank to blank."
		if self.respond_to?(attr)
			if (self.send("#{attr}_was").blank? && self.send("#{attr}").blank?)
				
				true
			end
		end
	end

	##now what if both have changed?
	def email_and_additional_login_param_both_changed
		#puts "calling email and additional login param both changed"
		##add error saying you cannot change both at the same time.
		##additional login param can change as long as neither goes from nil to blank or blank to nil.

		if email_changed? && !attr_blank_to_blank?("email") && additional_login_param_changed? && !attr_blank_to_blank?("additional_login_param")
			errors.add(:email,"you cannot update your email and #{additional_login_param_name} at the same time")
		end
	end

	## no longer used.
	def set_client_authentication?(act_name,cont_name,client)
		
		client && act_name != "destroy" && !(["passwords","confirmations","unlocks"].include? cont_name)
		
		
	end


	##this def is used to determine if the auth_token and es should
	##be sent back.
	def reply_with_auth_token_es?(client,curr_user)

		 ##we have a client authentication for the client.
         ##we have an authentication token
         ##we are signed_in
         ##we have at least one authentication_key confirmed.
         return false if !curr_user
         client && client_authentication[client.current_app_id] && authentication_token && (id.to_s == curr_user.id.to_s) && at_least_one_authentication_key_confirmed?
	end

	##just a combination of having the redirect_url and the above method,
	##and whether to redirect or not.
	def reply_with_redirect_url_and_auth_token_and_es?(redirect_url,client,curr_user)
		
		Auth.configuration.do_redirect && redirect_url && reply_with_auth_token_es?(client,curr_user)
	end

	##
	def token_expired?
		if authentication_token_expires_at < Time.now.to_i
			## the before_save callback in omniauth.rb, will automatically regenerate the authentication token
			#save
			true
		end
	end

	

	##returns the additional login param name.
	def additional_login_param_name
		Auth.configuration.auth_resources[self.class.name.to_s.underscore.capitalize][:additional_login_param_name]
	end

	## => resource name converted to string with a capital 
	## => first letter. eg : "User" 
	def resource_key_for_auth_configuration
		self.class.name.to_s.underscore.capitalize
	end

	##THIS DEF CAN BE OVERRIDDEN IN YOUR MODEL TO SUIT YOUR NEEDS.
	def has_phone
		Auth.configuration.auth_resources[resource_key_for_auth_configuration][:additional_login_param_name] && Auth.configuration.auth_resources[resource_key_for_auth_configuration][:additional_login_param_name] == "mobile"  
	end
		
	##override as needed.
	##currently used in _gateway.html.erb
	def resource_first_name
		name
	end
	
	## this method is to be overridden, it returns the value of the admin_variable.
	## it can be used to decide if the user is an admin.
	## @used_in : payment_concern in the refund_callback 
	def is_admin?(args=nil)
		admin
	end



	## @return[Boolean] true/false : override to decide how the user decides if it can create discount coupons for its contents or not.
	## the current implementation returns true by default
	def can_create_discount_coupons?
		true
	end


	
	####################################################################
	###
	###
	### GCM - AMAZON ENDPOINT
	###
	###
	####################################################################
	def refresh_endpoints
		
		if self.android_token_changed?
			endpoint = Auth::Endpoint.new
			endpoint.android_token = self.android_token
			self.android_endpoint = endpoint.set_android_endpoint
		end
		
	end

	################################################################
	##
	##
	## OWNERSHIP.
	##
	##
	################################################################
	def is_owner?(object)
		raise "object does not have a resource id field" unless ((object.respond_to? :resource_id) || (object.respond_to? :resource_class))
		return true if ((object.resource_class == self.resource_class) && (object.resource_id == self.resource_id))
		return false
	end

	################################################################
	##
	##
	## AUTOCOMPLETE CONCERN PART.
	##
	##
	################################################################


    ## so the user's will have to give a unique id,
    ## what if they want you to check that ?
    def set_autocomplete_tags
      if self.new_record?
         self.tags << "user"
         self.tags << self.name
         self.tags << self.email
         self.tags << self.additional_login_param
      end
    end

    def set_primary_link
      self.primary_link = Rails.application.routes.url_helpers.profile_path(:id => self.id.to_s, :resource => self.class.name.pluralize.downcase)
    end

    ## ill take it from here onwards.

    ## now first we are going to test it with the ui.
    ## and we are going to test it with one admin and one non admin account
    ## before that, we are going to 
    def set_secondary_links    		
   	    unless self.secondary_links["Add New Account"]
			self.secondary_links["Add New User"] = {
				:partial => "auth/admin_create_users/search_results/add_new_user.html.erb",
				:instance_name_in_locals => "user", 
				:other_locals => {}
			}
		end
		unless self.secondary_links["Manage This Account"]
			self.secondary_links["Manage This User"] = {
				:partial => "auth/admin_create_users/search_results/manage_user.html.erb",
				:instance_name_in_locals => "user", 
				:other_locals => {}
			}
		end
		unless self.secondary_links["Set Unset Proxy"]
			self.secondary_links["Set Unset Proxy"] = {
				:partial => "auth/profiles/search_results/switch_to_user.html.erb",
				:instance_name_in_locals => "user", 
				:other_locals => {}
			}
		end
		
		## switch to the user, and see all associated people.

		unless self.secondary_links["See All Associated People"]
			self.secondary_links["See All Associated People"] = {
				:url => Rails.application.routes.url_helpers.send(Auth::OmniAuth::Path.create_or_index_path(Auth.configuration.personality_class))
			}
		end

    end

end
