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
    field :app_ids, type: Array, default: []
    field :current_app_id, type: String
    attr_accessor :add_app_id
    attr_accessor :add_redirect_url
    
    
    def contains_redirect_url?(url)
        return self.redirect_urls.include? url
    end

    def self.find_valid_api_key(api_key)
        c =  self.find(:api_key => api_key)
        return c
    end

    ##USED IN DEVISE.RB -> SET_CLIENT
    ##USED IN OMNIAUTH.RB -> CHECK_STATE
    def self.find_valid_api_key_and_app_id(api_key,app_id)
        c = self.where(:api_key => api_key, :app_ids => app_id).first
        if c
            c.current_app_id = app_id
        end
        return c
    end

    def there_are_redirect_urls
        return self.redirect_urls && self.redirect_urls.size > 0
    end

    

  end
end
