module Auth
  class Client
    include Mongoid::Document
    include MongoidVersionedAtomic::VAtomic
    validates :redirect_urls, :url => true, if: :there_are_redirect_urls
    validates :user_id, presence: true

    def to_param
    	user_id
    end

    def self.find(input)
    	Client.where(:user_id => input).first
    end

    field :api_key, type: String
    field :path, type: String
    field :redirect_urls, type: Array, default: []
    field :user_id, type: BSON::ObjectId, default: BSON::ObjectId.new
    
    def contains_redirect_url?(url)
        return self.redirect_urls.include? url
    end

    def self.is_active(api_key)
        
    end

    def there_are_redirect_urls
        return self.redirect_urls.size > 0
    end

  end
end
