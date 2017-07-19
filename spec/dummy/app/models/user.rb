class User
  include Mongoid::Document
  include Auth::Concerns::UserConcern
  field :name, type: String
  field :dog, type: String

  def self.find_for_database_authentication(warden_conditions)
		#puts "came to find for database authenticatable with warden conditions"
		#puts warden_conditions.to_s
		conditions = warden_conditions.dup
		#puts "the conditions are :"
		#puts conditions.to_s
		#conditions = {:login => conditions[:email]}
		puts "conditions are"
		puts conditions.to_s
		if login = conditions.delete(:login)
			login = login.downcase
	  		where(conditions).where('$or' => [ {:mobile => /^#{Regexp.escape(login)}$/i}, {:email => /^#{Regexp.escape(login)}$/i} ]).first
		else
			#puts "came to the alternate."
	  		where(conditions).first
		end
  end 

  ##FUNCTION OVERRIDEN FROM THE USER CONCERN TO FORMAT AND PARSE THE ADDITIONAL_LOGIN_PARAM.
  ##here we are processing it assuming it is a mobile number
  ##the regex is the same one used on the javascript side as well.
  def additional_login_param_format
  	if !additional_login_param.blank?
  		if !additional_login_param =~/^([0]\+[0-9]{1,5})?([7-9][0-9]{9})$/
  			errors.add(:additional_login_param,"please enter a valid mobile number")
  		end
  	end
  end

end
