module Auth
	class Identity
	  include Mongoid::Document
	  
	  field :provider, type: String, default: ""
	  field :uid, type: String, default: ""
	  field :email, type:String, default: ""
	  field :access_token, type:String
	  field :token_expires_at, type:Integer

	  def has_provider?
		return (self.provider != "")
	  end

	  def build_from_omnihash(omni_hash)
	  	self.email,self.uid,self.provider,self.access_token,self.token_expires_at = omni_hash["info"]["email"],omni_hash["uid"],omni_hash["provider"],omni_hash["credentials"]["token"],omni_hash["credentials"]["expires_at"]	
	  	self
	  end

	end

	
end