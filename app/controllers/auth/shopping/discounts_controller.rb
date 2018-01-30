class Auth::Shopping::DiscountsController < Auth::Shopping::ShoppingController
  
  ## only these actions need an authenticated user to be present for them to be executed.
  CONDITIONS_FOR_TOKEN_AUTH = [:create,:update,:destroy,:edit,:new,:index,:show]

  TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
  ##this ensures api access to this controller.
  include Auth::Concerns::DeviseConcern
  include Auth::Concerns::TokenConcern
  before_filter :do_before_request , TCONDITIONS
  before_filter :initialize_vars , TCONDITIONS

  ## remember to add the before_filter is_admin as well.

  

end
