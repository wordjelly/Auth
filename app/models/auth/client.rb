module Auth
  class Client
    include Mongoid::Document
    include MongoidVersionedAtomic::VAtomic
    
    def to_param
    	user_id
    end

    def self.find(input)
    	Client.where(:user_id => input).first
    end

    field :api_key, type: String
    field :path, type: String
    field :redirect_urls, type: Array, default: [""]
    field :user_id, type: BSON::ObjectId
    
    def contains_redirect_url?(url)
        return self.redirect_urls.include? url
    end

  end
end
