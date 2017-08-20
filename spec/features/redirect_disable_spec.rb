require "rails_helper"

RSpec.feature "", :type => :feature, :disable_redirect => true, :js => true  do

  before(:each) do 
        Auth.configuration.do_redirect = false
        Auth.configuration.recaptcha = false
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

  after(:each) do 
        Auth.configuration.do_redirect = true
        Auth.configuration.recaptcha = true
  end

  scenario " -- disabling the redirect url feature , leads to no redirects " do 
            
            ##visit the sign in page
            visit new_user_session_path({:redirect_url => "http://www.google.com", :api_key => @ap_key, :current_app_id => "test_app_id"})

            
            ##visit the sign up page.
            click_link("Sign In")
            
            wait_for_ajax
            
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
            expect(page).to have_text("Sign Out")
            expect(current_url =~ /google/).not_to be_truthy
            
  end

end