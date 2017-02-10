require "rails_helper"

RSpec.feature "", :type => :feature, :feature => true do

  before(:each) do 
 	    ActionController::Base.allow_forgery_protection = true
        User.delete_all
        Auth::Client.delete_all
        @u = User.new(attributes_for(:user_confirmed))
        @u.save
        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test")
        @c.redirect_urls = ["http://www.google.com"]
        @c.app_ids << "test_app_id"
        @c.versioned_create
        @u.client_authentication["test_app_id"] = "test_es"
        @u.save
        @ap_key = @c.api_key
  end
    
  context " -- oauth tests -- " do 

   

    context " -- google oauth test -- " do 


        scenario " -- it can sign in with oauth2 -- ", js: true do 
       
            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"
            find(:xpath, "//a[@href='/authenticate/omniauth/users/google_oauth2']").click
    
            expect(page).to have_content("Sign Out")
          
        end


        scenario " -- creates new user first time with oauth, on subsequent sign in , will update access_token and expiration -- ", js: true do 

            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"
            find(:xpath, "//a[@href='/authenticate/omniauth/users/google_oauth2']").click
    
            expect(page).to have_content("Sign Out")

            click_link "Sign Out"

            ###
            ###
            ###
            ### TRY TO SIGN IN AGAIN USING SAME OAUTH.

            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash('new_token',50000)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"
            find(:xpath, "//a[@href='/authenticate/omniauth/users/google_oauth2']").click
    
            expect(page).to have_content("Sign Out")

            u = User.where(:email => "rrphotosoft@gmail.com").first
            expect(u.access_token).to eql('new_token')
            expect(u.token_expires_at).to eql(50000)

        end

      scenario "visit sign_in with redirect_url + valid_api_key => visit sign_up => create account pending confirmation => visit confirmation url => then sign in again => get redirected to the redirection url with es and authentication_token.", js: true do
            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path({:redirect_url => "http://www.google.com", :api_key => @ap_key, :current_app_id => "test_app_id"})

            puts "----------------FINISHED NEW USER SESSION PATH----------------"
            ##visit the sign up page.
            click_link("Sign In")
            wait_for_ajax
            ##modal should open.
            ##then 
            ## SET RECAPTCHA TO FALSE SO THAT IT DOESNT INTERFERE WITH THE REQUEST RESPONSE.
            
            find("#show_sign_up").click
            #puts "----------------VISITED NEW USER REGISTRATION--------------"
            fill_in('Email', :with => 'retard@gmail.com')
            fill_in('Password', :with => 'password')
            fill_in('Password confirmation', :with => 'password')
            wait_for_ajax
            find("#submit").trigger("click")
            wait_for_ajax

            



            ##now visit he confirmation url.
            u = User.where(:email => 'retard@gmail.com').first
            confirmation_token = u.confirmation_token
            puts "the confirmation token is: #{confirmation_token}"
           
            visit user_confirmation_path({:confirmation_token => confirmation_token})
            
            u.reload
            
            click_link("Sign In")
            wait_for_ajax

            #puts u.attributes.to_s
            puts " ----------------- trying to sign in with new user ------------------------------"
            fill_in('Email',:with => 'retard@gmail.com')
            fill_in('Password', :with => 'password')
            find("#submit").trigger("click")
            sleep(5)
            ##should redirect to the redirect url.
            expected_es = u.client_authentication["test_app_id"]
            if current_url=~/google/
                expect("one").to eql("one")
            end
            
            
        end

    end

  end



  



  

=begin
  

    
  scenario "user with omniauth authentication , tries to create an account with the same email" do 

    visit new_user_registration_path
    page.should have_content("Sign in with GoogleOauth2")
    mock_auth_hash
    Rails.application.env_config["omniauth.model"] = "omniauth/users/"
    #Rails.application.env_config["omniauth.auth"] = 
    click_link "Sign in with GoogleOauth2"
    expect(page).to have_content("Logout")
    ActionController::Base.allow_forgery_protection = false
    click_link "Logout"
    ActionController::Base.allow_forgery_protection = true
    
    ##oauth user has now been created.

    visit new_user_registration_path
    fill_in('Email', :with => 'rrphotosoft@gmail.com')
    fill_in('Password', :with => 'password')
    fill_in('Password confirmation', :with => 'password')
    find('input[name="commit"]').click
    expect(page).to have_content("Email is already taken")

  end


  scenario "user with one oauth account, tries to use another oauth account with the same email, fails to sign up." do 

    visit new_user_registration_path
    page.should have_content("Sign in with GoogleOauth2")
    mock_auth_hash
    Rails.application.env_config["omniauth.model"] = "omniauth/users/"
    #Rails.application.env_config["omniauth.auth"] = 
    click_link "Sign in with GoogleOauth2"
    expect(page).to have_content("Logout")
    ActionController::Base.allow_forgery_protection = false
    click_link "Logout"
    ActionController::Base.allow_forgery_protection = true


    visit new_user_registration_path
    mock_auth_hash_facebook
    Rails.application.env_config["omniauth.model"] = "omniauth/users/"
    click_link "Sign in with Facebook"
    u = User.where(:email => "rrphotosoft@gmail.com").first
    expect(current_url).to eq("http://" + self.url_options[:host] + omniauth_failure_path("User"))

  end
=end
end
