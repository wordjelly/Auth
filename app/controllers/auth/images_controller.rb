class Auth::ImagesController < Auth::AuthenticatedController
    
  include Auth::Images::ImagesHelper

  def new
    puts "came to the overridden def."
    @model.parent_id = BSON::ObjectId.new.to_s
    @model.parent_class = "test"
  end
  
  def webhook_endpoint

  end


end
