##this is to be mixed into the user profile, no seperate live controller
##is needed for this.
module Auth::Concerns::Shopping::CartControllerConcern

  extend ActiveSupport::Concern

  included do

  end

  def show_cart
    ##collects everything, groups by day
    ##and then adds buttons to build transactions.
    ##should be able to select by day, also deselect.
    ##that is jquery side issues.
  end

end