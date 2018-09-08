class Admin
=begin
  include Mongoid::Document
  include Auth::Concerns::UserConcern
  field :name, type: String
  field :admin, type: Boolean, default: true

  def send_devise_notification(notification, *args)
	 devise_mailer.send(notification, self, *args).deliver_later
  end
=end
end
