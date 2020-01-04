# Preview all emails at http://localhost:3000/rails/mailers/new
class NewPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/new/send_notification
  def notification
  	u = User.new
  	u.email = "bhargav.r.raut@gmail.com"
  	n = Noti.new
  	n.email_subject = "notification subject set from preview."
    New.notification(u,n)
  end

end
