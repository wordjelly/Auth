module Auth
	class Identity
	  include Mongoid::Document
	  
	  field :provider, type: String, default: ""
	  field :uid, type: String, default: ""
	  field :email, type:String, default: ""

	  def has_provider?
		return (self.provider != "")
	  end

	end

	
end