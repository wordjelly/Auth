module Auth
	class Identity
	  include Mongoid::Document
	  
	  field :provider, type: String
	  field :uid, type: String
	  field :email, type:String

	end
end