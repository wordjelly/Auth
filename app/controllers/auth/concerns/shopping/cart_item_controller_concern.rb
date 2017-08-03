module Auth::Concerns::Shopping::CartItemControllerConcern

  extend ActiveSupport::Concern

  included do

  end

  ##expects the product id, user_id is the logged in user, and quantity 
  def create

  end

  ##only permits the quantity to be changed, transaction id is internally assigned and can never be changed by the external world.
  def update

  end

  ##can be removed.
  def destroy

  end

end
