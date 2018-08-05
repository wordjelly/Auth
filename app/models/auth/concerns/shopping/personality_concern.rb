module Auth::Concerns::Shopping::PersonalityConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::OwnerConcern
	include Auth::Concerns::EsConcern
	include Mongoid::Autoinc	


	included do 

		INDEX_DEFINITION = {
			index_options:  {
			        settings:  {
			    		index: Auth::Concerns::EsConcern::AUTOCOMPLETE_INDEX_SETTINGS
				    },
			        mappings: {
			          Auth::OmniAuth::Path.pathify(Auth.configuration.personality_class) => Auth::Concerns::EsConcern::AUTOCOMPLETE_INDEX_MAPPINGS
			    }
			}
		}

		## this will get stored as an epoch.
		field :date_of_birth, type: String
		
		## full name
		field :fullname, type: String

		## this is a simple field that is set whenever the date of birth is set.
		field :age, type: Integer

		field :sex, type: String


		##################################################################
		##
		##
		## AUTOINCREMENTING AND HASHID
		##
		##
		##################################################################

		field :auto_incrementing_number, type: Integer

		increments :auto_incrementing_number

		field :unique_hash_id, type: String

	end

	###############################################################
	##
	##
	## METHOD OVERRIDDEN BECAUSE MONGOID-AUTOINC, CALLS THIS METHOD TO SET THE VALUE OF THE AUTOINCREMENTING FIELD, AND WE NEEDED TO HOOK INTO THAT TO SET THE HASHID. 
	##
	##
	###############################################################

	def write_attribute(field,value)
		super(field,value)
		if field.to_s == "auto_incrementing_number"
			if self.auto_incrementing_number_changed?
				unless self.unique_hash_id
					hashids = Hashids.new(Auth.configuration.hashids_salt,0,Auth.configuration.hashids_alphabet)
					self.unique_hash_id = hashids.encode(self.auto_incrementing_number)
				end
			end
		end
	end

	################################################################

	## adds the name, sex, age in years, and the unique hash id for this personality
	def add_info(tags)
		tags << self.fullname
		tags << self.sex
		tags << ("Age: " + self.age.to_s + " years")
		tags << self.unique_hash_id
	end

	## date of birth is going to be a simple string.
	## format : YYYY-DD-MM, zero padded in case of single digits
	## so this sets the age, now what.
	def date_of_birth=(date_of_birth)
		
		super(date_of_birth)
		return unless date_of_birth

		birth_time = Time.parse(date_of_birth)
		self.age = ((Time.now - birth_time)/1.year).to_i
	end


	######################################################################
	##
	##
	## AUTOCOMPLETE METHODS.
	##
	##
	######################################################################

	## @param[Hash] options : can contain a :resource key. which should be the resource(user) to which all the personalities belong.
	module ClassMethods
		def find_personalities(options)
			conditions = {:resource_id => nil, :parent_id => nil}
			conditions[:resource_id] = options[:resource].id.to_s if options[:resource]
			puts "conditions are:"
			puts conditions.to_s
			Auth.configuration.personality_class.constantize.where(conditions)
		end
	end
end