# Preview all emails at http://localhost:3000/rails/mailers/new
class NewPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/new/send_notification
  def send_notification
    New.send_notification
  end

end
