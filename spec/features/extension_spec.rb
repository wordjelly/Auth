require "rails_helper"

RSpec.feature "user visits, seeking authentication", :type => :feature do
  before(:each) do 
 	 User.delete_all
   	 Auth::Client.delete_all
  	 @user = User.new(attributes_for(:user))
  	 @user.save
  	 @cli = Auth::Client.new(:user_id => @user.id, :api_key => "test", :redirect_urls => ["http://www.google.com"])
  	 @cli.versioned_create
  	 @api_key = @cli.api_key
  end
  scenario "User visits sign in page, and then clicks sign up" do
    visit "/authenticate/users/sign_in?api_key=#{@api_key}&redirect_url=http://wwww.google.com"
    click_link("Sign up")
    expect(page).to have_text("client in session")
  end
end