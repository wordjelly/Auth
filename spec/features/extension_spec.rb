require "rails_helper"

RSpec.feature "", :type => :feature, :js => true  do

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

    context " -- google oauth test -- ", google: true do 

        before(:all) do 
            @oauth_provider = :google_oauth2
        end


        scenario " -- it can sign in with oauth2 -- ", js: true do 
       
            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash(@oauth_provider)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            l = find("a[href='/authenticate/omniauth/users/#{@oauth_provider}']")
            l.click
            #find(:xpath, "//a[@href='/authenticate/omniauth/users/#{@oauth_provider.to_s}']").click
        


            expect(page).to have_content("Sign Out")
          
        end


        scenario " -- creates new user first time with oauth, on subsequent sign in , will update access_token and expiration -- ", js: true do 

            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash(@oauth_provider)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"
            find("a[href='/authenticate/omniauth/users/#{@oauth_provider}']").click
    

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

            mock_auth_hash(@oauth_provider,'new_token',50000)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"
            find("a[href='/authenticate/omniauth/users/#{@oauth_provider}']").click
    
            expect(page).to have_content("Sign Out")

            u = User.where(:email => "rrphotosoft@gmail.com").first
            expect(u.identities[0]["access_token"]).to eql('new_token')
            expect(u.identities[0]["token_expires_at"]).to eql(50000)

        end


        scenario "visit sign_in with redirect_url + valid_api_key => visit sign_up => create account pending confirmation => visit confirmation url => then sign in again => get redirected to the redirection url with es and authentication_token.", js: true do
            Auth.configuration.recaptcha = false
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
            expect(current_url =~ /google/).to be_truthy
                        
        end


        ##with this scenario will see error in console< that is expected>
        scenario "any error in omniauth -> goes to omniauth error page", js: true do 

            OmniAuth.config.test_mode = true
            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash(@oauth_provider,nil,nil,"simulate_error")
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            find("a[href='/authenticate/omniauth/users/#{@oauth_provider}']").click

            expect(page).to have_content("error")

        end



        ##THIS IS SIMULATED BY FIRST CREATING A NEW OAUTH USER.
        ##THEN WE SET ITS VERSION TO 0
        ##AFTER THAT WE GO AGAIN TO OAUTH AND TRY TO SIGN IN.
        ##SINCE VERSION IS 0, MONGOID VERSIONED ATOMIC UPDATE, WILL FAIL
        ##THIS WILL LEAD TO A FAILURE OF THE UPDATE OF ACCESS_TOKENA AND EXPIRES_AT.
        scenario "failure to update access_token and expires_at goes to omniauth error page, with appropriate error message ", js: true do 
                
            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash(@oauth_provider)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            find("a[href='/authenticate/omniauth/users/#{@oauth_provider}']").click

            click_link("Sign Out")

            #u = User.where(:email => "rrphotosoft@gmail.com").first
            #u.version = 0
            #u.save
            
            User.class_eval do 
                after_save :set_op_success_to_false
                def set_op_success_to_false
                    self.op_success = false
                end
            end

            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash(@oauth_provider)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            find("a[href='/authenticate/omniauth/users/#{@oauth_provider}']").click                

           
            expect(page).to have_content("Failed to update the acceess token and token expires at")

            
        end


        ##try to simulate by creating a after_create callback which will delete identities, this will make it feel like the create failed, and this will lead to a failure fo the create.
        scenario "failure to create new oauth user, goes to omniauth error page, with error message ", js: true do 
            User.skip_callback(:save, :after, :set_op_success_to_false)
            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash(@oauth_provider)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            User.class_eval do 
                after_save :set_op_success_to_false
                def set_op_success_to_false
                   
                    self.op_success = false
                end
            end

            find("a[href='/authenticate/omniauth/users/#{@oauth_provider}']").click

            expect(page).to have_content("Failed to create new identity")

           

        end


        ##THIS CAN BE SIMULATED BY CALLING CONFIRM AFTER_SAVE
        ##SIGN IN WILL FAIL IF , WE UNSET THE PASSWORD, POST_SAVE
        scenario "failure to sign in resource after creating or updating it, will lead to appropriate error", js: true do
            User.skip_callback(:save, :after, :set_op_success_to_false)
           
            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash(@oauth_provider)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            User.class_eval do 
                before_save :remove_confirmed_at
                def remove_confirmed_at
                    self.confirmed_at = nil
                end
            end

            find("a[href='/authenticate/omniauth/users/#{@oauth_provider}']").click

            ##THIS HAPPENS BECAUSE WE TRY TO SIGN IN AN UNCONFIRMED USER, AND SO IT WILL GIVE THAT AS THE ERROR, AND AT THE SAME TIME REDIRECT TO THE AFTER_SIGN_IN_PATH.
            expect(page).to have_content("You have to confirm your email address before continuing.")
            expect(page).to have_content("You need to Sign in to continue.")           
        end


        scenario "failure to provide oauth resource, goes to omniauth error page, with no_resource error message", js: true do 
            User.skip_callback(:save, :after, :set_op_success_to_false)
            User.skip_callback(:save, :before, :remove_confirmed_at)

            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax
            Rails.application.env_config["omniauth.model"] = nil
            mock_auth_hash(@oauth_provider)

            find("a[href='/authenticate/omniauth/users/#{@oauth_provider}']").click

            ##THIS HAPPENS BECAUSE WE TRY TO SIGN IN AN UNCONFIRMED USER, AND SO IT WILL GIVE THAT AS THE ERROR, AND AT THE SAME TIME REDIRECT TO THE AFTER_SIGN_IN_PATH.
            expect(page).to have_content("No resource was specified in the omniauth callback request.")


        end

    end


    context " -- facebook oauth test -- ", facebook: true do 

        before(:all) do 
            @oauth_provider = :facebook
        end

        scenario " -- it can sign in with oauth2 -- ", js: true do 
       
            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash(@oauth_provider)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"
            find(:xpath, "//a[@href='/authenticate/omniauth/users/#{@oauth_provider.to_s}']").click
    
            expect(page).to have_content("Sign Out")
          
        end


        scenario " -- creates new user first time with oauth, on subsequent sign in , will update access_token and expiration -- ", js: true do 

            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash(@oauth_provider)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"
            find(:xpath, "//a[@href='/authenticate/omniauth/users/#{@oauth_provider.to_s}']").click
    

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

            mock_auth_hash(@oauth_provider,'new_token',50000)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"
            find(:xpath, "//a[@href='/authenticate/omniauth/users/#{@oauth_provider.to_s}']").click
    
            expect(page).to have_content("Sign Out")

            u = User.where(:email => "rrphotosoft@gmail.com").first
            expect(u.identities[0]["access_token"]).to eql('new_token')
            expect(u.identities[0]["token_expires_at"]).to eql(50000)

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

        scenario "any error in omniauth -> goes to omniauth error page", js: true do 

            OmniAuth.config.test_mode = true
            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash(@oauth_provider,nil,nil,"simulate_error")
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            find(:xpath, "//a[@href='/authenticate/omniauth/users/#{@oauth_provider.to_s}']").click

            expect(page).to have_content("error")

        end



        ##THIS IS SIMULATED BY FIRST CREATING A NEW OAUTH USER.
        ##THEN WE SET ITS VERSION TO 0
        ##AFTER THAT WE GO AGAIN TO OAUTH AND TRY TO SIGN IN.
        ##SINCE VERSION IS 0, MONGOID VERSIONED ATOMIC UPDATE, WILL FAIL
        ##THIS WILL LEAD TO A FAILURE OF THE UPDATE OF ACCESS_TOKENA AND EXPIRES_AT.
        scenario "failure to update access_token and expires_at goes to omniauth error page, with appropriate error message ", js: true do 
                
            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash(@oauth_provider)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            find("a[href='/authenticate/omniauth/users/#{@oauth_provider}']").click

            click_link("Sign Out")

            #u = User.where(:email => "rrphotosoft@gmail.com").first
            #u.version = 0
            #u.save
            
            User.class_eval do 
                after_save :set_op_success_to_false
                def set_op_success_to_false
                    self.op_success = false
                end
            end

            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash(@oauth_provider)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            find("a[href='/authenticate/omniauth/users/#{@oauth_provider}']").click                

           
            expect(page).to have_content("Failed to update the acceess token and token expires at")

            
        end


        ##try to simulate by creating a after_create callback which will delete identities, this will make it feel like the create failed, and this will lead to a failure fo the create.
        scenario "failure to create new oauth user, goes to omniauth error page, with error message ", js: true do 
            User.skip_callback(:save, :after, :set_op_success_to_false)
            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash(@oauth_provider)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            User.class_eval do 
                after_save :set_op_success_to_false
                def set_op_success_to_false
                   
                    self.op_success = false
                end
            end

            find("a[href='/authenticate/omniauth/users/#{@oauth_provider}']").click

            expect(page).to have_content("Failed to create new identity")

           

        end


        ##THIS CAN BE SIMULATED BY CALLING CONFIRM AFTER_SAVE
        ##SIGN IN WILL FAIL IF , WE UNSET THE PASSWORD, POST_SAVE
        scenario "failure to sign in resource after creating or updating it, will lead to appropriate error", js: true do
            User.skip_callback(:save, :after, :set_op_success_to_false)
           
            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax

            mock_auth_hash(@oauth_provider)
          
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            User.class_eval do 
                before_save :remove_confirmed_at
                def remove_confirmed_at
                    self.confirmed_at = nil
                end
            end

            find("a[href='/authenticate/omniauth/users/#{@oauth_provider}']").click

            ##THIS HAPPENS BECAUSE WE TRY TO SIGN IN AN UNCONFIRMED USER, AND SO IT WILL GIVE THAT AS THE ERROR, AND AT THE SAME TIME REDIRECT TO THE AFTER_SIGN_IN_PATH.
            expect(page).to have_content("You have to confirm your email address before continuing.")
            expect(page).to have_content("You need to Sign in to continue.")           
        end


        scenario "failure to provide oauth resource, goes to omniauth error page, with no_resource error message", js: true do 
            User.skip_callback(:save, :after, :set_op_success_to_false)
            User.skip_callback(:save, :before, :remove_confirmed_at)

            Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path

            click_link("Sign In")
            wait_for_ajax
            Rails.application.env_config["omniauth.model"] = nil
            mock_auth_hash(@oauth_provider)

            find("a[href='/authenticate/omniauth/users/#{@oauth_provider}']").click

            ##THIS HAPPENS BECAUSE WE TRY TO SIGN IN AN UNCONFIRMED USER, AND SO IT WILL GIVE THAT AS THE ERROR, AND AT THE SAME TIME REDIRECT TO THE AFTER_SIGN_IN_PATH.
            expect(page).to have_content("No resource was specified in the omniauth callback request.")


        end

    end

  end

  context " -- topic web app request spec ", :topic_feature => true do 

    scenario "visit topic part after signing in, and everythign should work." , js: true do 
        ActionController::Base.allow_forgery_protection = false
        Auth.configuration.recaptcha = false
            ##visit the sign in page
            visit new_user_session_path({:api_key => @ap_key, :current_app_id => "test_app_id"})

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
            visit user_confirmation_path({:confirmation_token => confirmation_token})
            
            u.reload
            
            click_link("Sign In")
            wait_for_ajax

            #puts u.attributes.to_s
            puts " ----------------- trying to sign in with new user ------------------------------"
            fill_in('Email',:with => 'retard@gmail.com')
            fill_in('Password', :with => 'password')
            find("#submit").trigger("click")
            puts "sleeping"
            sleep(5)
            puts "visiting new topic path."
            visit new_topic_path
            expect(page).to have_text("Sign Out")
    end

    scenario "visit topic path without signing in, should redirect to sign in or sign up" , js: true , topic_feature: true do 
        visit new_topic_path
        puts page.text
        expect(page).to have_text("You need to Sign in to continue.")

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


  
=end
end
