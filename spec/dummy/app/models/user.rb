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

  def additional_login_param_format
  	puts "-----------------------------YES WE ARE VALIDATING ---------------"
  end

end
