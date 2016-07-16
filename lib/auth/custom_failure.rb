class CustomFailure < Devise::FailureApp
  def redirect_url
    puts "the resource attempted to be logged in was: #{warden[:scope]}"
  end

  # You need to override respond to eliminate recall
  def respond
    redirect
  end

end