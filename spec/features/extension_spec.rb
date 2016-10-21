require "rails_helper"
=begin
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
  
  scenario "User visits sign in page with valid api_key and redirect_url, and then clicks sign up" do
    visit "/authenticate/users/sign_in?api_key=#{@api_key}&redirect_url=http://wwww.google.com"
    click_link("Sign up")
    expect(page).to have_text("client in session")
  end

  scenario "User first visits sign_in with valid api_key and redirect_url, and then goes and signs_up, expect to redirect to the redirect_url" do 
  	
  	visit "/authenticate/users/sign_in?api_key=#{@api_key}&redirect_url=http://www.google.com"
    click_link("Sign up")
    fill_in('Email', :with => 'retard@gmail.com')
    fill_in('Password', :with => 'password')
    fill_in('Password confirmation', :with => 'password')
	find('input[name="commit"]').click
	##admittedly hacky way to get the last generated user.
	u = User.where(:email => 'retard@gmail.com').first

	
	expect(current_url).to eq("http://www.google.com/?authentication_token=#{u.authentication_token}&es=#{u.es}")
	
  end

end
=end