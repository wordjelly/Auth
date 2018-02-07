class Auth::Shopping::DiscountsController < Auth::Shopping::ShoppingController
  
  include Auth::Concerns::Shopping::DiscountControllerConcern
  ## only these actions need an authenticated user to be present for them to be executed.
  ## SHOW IS EXCLUDED SO THAT NON SIGNED IN USERS CAN view any discount/ product bundle.
  CONDITIONS_FOR_TOKEN_AUTH = [:create,:update,:destroy,:edit,:new,:index]

  TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
  ##this ensures api access to this controller.
  include Auth::Concerns::DeviseConcern
  include Auth::Concerns::TokenConcern
  before_filter :do_before_request , TCONDITIONS
  before_filter :initialize_vars , TCONDITIONS

  ## remember to add the before_filter is_admin as well.

  

end
