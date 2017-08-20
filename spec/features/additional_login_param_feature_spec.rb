#additional_login_param_feature_spec.rb
require "rails_helper"

RSpec.feature "additional login param + its redirect", :otp_feature => true, :type => :feature, :js => true  do

  before(:each) do 
      Auth.configuration.stub_otp_api_calls
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

  scenario " -- signs up with otp system -- " do 

            ActionController::Base.allow_forgery_protection = false
            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path()
            
            ##visit the sign up page.
            click_link("Sign In")
            wait_for_ajax
            ##modal should open.
            ##then 
            ## SET RECAPTCHA TO FALSE SO THAT IT DOESNT INTERFERE WITH THE REQUEST RESPONSE.
            
            find("#show_sign_up").click
            #puts "----------------VISITED NEW USER REGISTRATION--------------"
            fill_in('Email', :with => '9822028511')
            fill_in('Password', :with => 'password')
            fill_in('Password confirmation', :with => 'password')
            wait_for_ajax
            find("#submit").trigger("click")
            wait_for_ajax 

            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            old_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")

            fill_in('user_otp', :with => old_session_id)
            find('#otp_submit').click
            wait_for_ajax
            #expect(page).to have_text("Verifying your OTP")
            wait_for_ajax
            ##search for the user account with additio
            u = User.where(:additional_login_param => '9822028511', :additional_login_param_status => 2).first
            
            expect(u).not_to be_nil



  end

  
end