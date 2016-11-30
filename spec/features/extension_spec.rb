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
  scenario "visit sign_in with redirect_url + valid_api_key => visit sign_up => create account pending confirmation => visit confirmation url => then sign in again => get redirected to the redirection url with es and authentication_token." do

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
    fill_in('Email',:with => 'retard@gmail.com')
    fill_in('Password', :with => 'password')
    find('input[name="commit"]').click

    ##should redirect to the redirect url.
    expect(current_url).to eq("http://www.google.com/?authentication_token=#{u.authentication_token}&es=#{u.es}")
    
  end

  scenario "it can sign in with oauth2" do 

    visit new_user_registration_path
    page.should have_content("Sign in with GoogleOauth2")
    mock_auth_hash
    Rails.application.env_config["omniauth.model"] = "omniauth/users/"
    #Rails.application.env_config["omniauth.auth"] = 
    click_link "Sign in with GoogleOauth2"
    expect(page).to have_content("Logout")
  end

  scenario "go to sign_up with a valid_api_key and redirect_url => do oauth2 => should get redirected to redirect url with es and authentication token", :focus => true do 

    visit new_user_session_path({:redirect_url => "http://www.google.com", :api_key => @api_key})
    click_link("Sign up")
    mock_auth_hash
    Rails.application.env_config["omniauth.model"] = "omniauth/users/"
    click_link "Sign in with GoogleOauth2"
    u = User.where(:email => 'rrphotosoft@gmail.com').first
    expect(current_url).to eq("http://www.google.com/?authentication_token=#{u.authentication_token}&es=#{u.es}")

  end
    
  scenario "user with omniauth authentication , tries to create an account with the same email" do 

  end

  scenario "user with one oauth account, tries to use another oauth account with the same email" do 


  end
=end
    
  scenario "create client app id, create new user , confirm him, token authentication should work, on topics controller" do 

    

  end

end
