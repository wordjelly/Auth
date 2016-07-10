module Auth
  class Client
    include Mongoid::Document
    include MongoidVersionedAtomic::VAtomic

    ##the path of the omniauth, used trnasiently.
    field :api_key, type: String
    field :redirect_urls, type: Array, default: []
    field :user_id, type: BSON::ObjectId
    field :path, type: String

  end
end
