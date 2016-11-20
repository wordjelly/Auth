module Auth
  class Client
    include Mongoid::Document
    include MongoidVersionedAtomic::VAtomic
    validates :redirect_urls, :url => true, if: :there_are_redirect_urls
    validates :resource_id, presence: true

    def to_param
    	resource_id
    end

    def self.find(input)
    	Client.where(:resource_id => input).first
    end

    field :api_key, type: String
    field :path, type: String
    field :redirect_urls, type: Array, default: []
    field :resource_id, type: BSON::ObjectId, default: BSON::ObjectId.new
    
    def contains_redirect_url?(url)
        return self.redirect_urls.include? url
    end

    def self.find_valid_api_key(api_key)
        c =  self.find(:api_key => api_key)
        return c
    end

    def there_are_redirect_urls
        return self.redirect_urls.size > 0
    end

  end
end
