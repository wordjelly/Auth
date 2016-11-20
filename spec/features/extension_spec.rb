require "rails_helper"

RSpec.feature "user visits, seeking authentication", :type => :feature do
  before(:each) do 
 	 User.delete_all
   	 Auth::Client.delete_all
  	 @user = User.new(attributes_for(:user_confirmed))
  	 @user.save
  	 @cli = Auth::Client.new(:resource_id => @user.id, :api_key => "test", :redirect_urls => ["http://www.google.com"])
  	 @cli.versioned_create
  	 @api_key = @cli.api_key
  end
  
=begin
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
=end

  scenario "visit sign_in with redirect_url + valid_api_key => visit sign_up => create account pending confirmation => visit confirmation url => get redirected to the redirection url with es and authentication_token." do

    ##visit the sign in page
    visit new_user_session_path({:redirect_url => "http://www.google.com", :api_key => @api_key})
    #puts "----------------FINISHED NEW USER SESSION PATH----------------"
    ##visit the sign up page.
    click_link("Sign up")
    #puts "----------------FINISHED NEW USER REGISTRATION--------------"
    fill_in('Email', :with => 'retard@gmail.com')
    fill_in('Password', :with => 'password')
    fill_in('Password confirmation', :with => 'password')
    find('input[name="commit"]').click
    #puts "--------------FINISHED CREATE REGISTRATION ACTION----------"
    ##now visit the confirmation url.
    u = User.where(:email => 'retard@gmail.com').first
    confirmation_token = u.confirmation_token
    #puts "the confirmation token is: #{confirmation_token}"
    visit user_confirmation_path({:confirmation_token => confirmation_token})
    #puts "-------------FINISHED USER CONFIRMATION PATH --------------"
    u.reload
    ##should redirect to the redirect url.
    expect(current_url).to eq("http://www.google.com/?authentication_token=#{u.authentication_token}&es=#{u.es}")
    
  end

end
