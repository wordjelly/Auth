class Admin
  include Mongoid::Document
  include Auth::Concerns::UserConcern
  field :name, type: String

  def send_devise_notification(notification, *args)
	 devise_mailer.send(notification, self, *args).deliver_later
  end
  ##############
  ##
  ##
  ## END OVERRIDE.
  ##
  ###############

  def is_admin?
    true
  end

end
