class HomeController < ApplicationController
  #before_action :authenticate_user!
  def index
  	
  end

  def send_notification
  	n = Noti.dummy
  	Auth::Notify.send_notification(n)
  end


end
