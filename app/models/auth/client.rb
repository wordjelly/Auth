module Auth
  class Client
    include Mongoid::Document
    include MongoidVersionedAtomic::VAtomic
    field :api_key, type: String
    field :redirect_urls, type: Array, default: []
    field :user_id, type: BSON::ObjectId
  end
end
