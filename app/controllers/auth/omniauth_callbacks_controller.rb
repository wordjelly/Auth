class Auth::OmniauthCallbacksController < DeviseController

  respond_to :json,:html
  include Auth::Concerns::OmniConcern

end
