require "rails_helper"

RSpec.describe "admin create user spec", :admin_create_user => true, :type => :request do 

	before(:all) do 
        ActionController::Base.allow_forgery_protection = false
        User.delete_all
        Auth::Client.delete_all
        Noti.delete_all
        ## THIS PRODUCT IS USED IN THE CART_ITEM FACTORY, TO 
        @u = User.new(attributes_for(:user_confirmed))
        @u.save

        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["testappid"] = "testestoken"
        @u.save
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["testappid"], "X-User-Aid" => "testappid"}
        

        ### okay so suppose you enter your mobile number.
        ### then you enter your email ?
        ### can we automatically shunt it.
        ### to another parameter?
        ### client side
        ### later send for verification.
        ### just call save on it.
        ### something that happens on verification.
        ### the same pathway that is taken when you add an email later on.
        ### no difference, but is triggered on verifying the mobile.
        ### we have to have another parameter on the user to store that.
        ### how do you verify the email?
        ### that is the question.
        ### otp => verified, added email -> waiting for verification.
        ### but cannot have both at the same time inputted.
        ### otp gives him account access.
        ### but not report by pdf.
        ### if he adds an email, does he need to verify it?
        ### just give a secondary option for the email.
        ### on verifying the sms, 


        ### CREATE ONE ADMIN USER

        ### It will use the same client as the user.
        @admin = User.new(attributes_for(:admin_confirmed))
        @admin.admin = true
        @admin.client_authentication["testappid"] = "testestoken2"
        @admin.save
        @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @admin.authentication_token, "X-User-Es" => @admin.client_authentication["testappid"], "X-User-Aid" => "testappid"}

        ## add this line to stub the otp api calls, while running the tests.
        Auth.configuration.stub_otp_api_calls = true
        
    end

    context  " -- json requests -- " do 

        context " -- create user with mobile -- ", :admin_create_user_with_mobile do 

            before(:example) do 
                u = User.where(:additional_login_param => "9561137096")
                u.first.delete if u.first
                $redis.flushall
                Noti.delete_all
            end
            
            it  " -- creates user and sends otp -- " do 

                post admin_create_users_path,{user: {:additional_login_param => "9561137096"},:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @admin_headers
                
                user_created = assigns(:auth_user)
                
                expect(user_created).not_to be_nil
                expect(user_created.errors).to be_empty

                session_id = get_otp_session_id(user_created)
                expect(session_id).not_to be_nil
                expect(response.code).to eq("201")
                response_body = JSON.parse(response.body)
                expect(response_body).to eq({"nothing" => true})

            end

            it  " -- resends the otp, if required -- ", :prob => true do 
                
                user_created = create_user_with_mobile
                initially_sent_otp = get_otp_session_id(user_created)
                
                get send_sms_otp_url({:resource => "users",:user => {:additional_login_param => user_created.additional_login_param},:api_key => @ap_key, :current_app_id => "testappid"}),nil,{ "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}

                new_otp = get_otp_session_id(user_created)

                expect(new_otp).not_to eq(initially_sent_otp)
                expect(new_otp).not_to be_nil
                response_body = JSON.parse(response.body)
                expect(response_body).to eq({"nothing" => true})
            end

            it  " -- verifies the otp, and sends reset password link on success -- ", :sends_reset_password => true do 

                user_created = create_user_with_mobile
                initially_sent_otp = get_otp_session_id(user_created)
                
                ## we expect typhoeus to make a call to the 

                # now call verify otp.
                get verify_otp_url({:resource => "users",:user => {:additional_login_param => user_created.additional_login_param, :otp => initially_sent_otp},:api_key => @ap_key, :current_app_id => "testappid"}),nil,{ "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
                
                user_json_hash = JSON.parse(response.body)
                expect(user_json_hash.keys).to match_array(["nothing"])

              
                expect(Noti.count).to eq(1)

            end

            it " -- can resend the password reset link if required -- " do 

                user_created = create_user_with_mobile
                initially_sent_otp = get_otp_session_id(user_created)
                verify_user_mobile(user_created)

                expect(Noti.count).to eq(1)

                req = {:id => user_created.id.to_s, :user => {:created_by_admin => true}, :resource => "users", api_key: @ap_key, :current_app_id => "testappid"}

                put profile_path({:id => user_created.id.to_s}),req.to_json,@admin_headers

                expect(response.code).to eq("204")
                
                expect(Noti.count).to eq(2)

            end

            it " -- does not send the reset password link on failure of verification -- " do 

                user_created = create_user_with_mobile
                initially_sent_otp = get_otp_session_id(user_created)
                unverify_user_mobile(user_created)

                expect(Noti.count).to eq(0)

                req = {:id => user_created.id.to_s, :user => {:created_by_admin => true}, :resource => "users", api_key: @ap_key, :current_app_id => "testappid"}

                put profile_path({:id => user_created.id.to_s}),req.to_json,@admin_headers

                expect(response.code).to eq("204")
                
                expect(Noti.count).to eq(0)

            end

            it " -- does not send the reset password link if the user subsequently changes his mobile number -- " do 

                ## first create the user
                ## then verify him
                ## then go and change the mobile number
                ## now let him go and verify that
                ## after that there should be no notification sent.
                user_created = create_user_with_mobile
                initially_sent_otp = get_otp_session_id(user_created)
                verify_user_mobile(user_created)
                ## after this one notification should be sent.
                expect(Noti.count).to eq(1)

                ## now update the user.
                update_mobile_number(user_created)

                ## now on doing this, again an otp should be sent.
                subsequently_sent_otp = get_otp_session_id(user_created)

                expect(initially_sent_otp).not_to eq(subsequently_sent_otp)
                expect(subsequently_sent_otp).not_to be_nil

                ## now again verify the user
                verify_user_mobile(user_created)

                ## but this time the notification should not be sent, because it is no longer the admin that is doing this.
                expect(Noti.count).to eq(1)

            end

        end

        context " --admin creates user with email -- ", :admin_creates_user_with_email do 

            before(:example) do 
                User.where(:email => "rrphotosoft@gmail.com").delete_all
                $redis.flushall
                Noti.delete_all
            end

            ## what if we create with email and mobile, solve this today.

            it " -- creates a user with first name, last name, dob and mobile -- ", :admin_creates_user_with_personal_details => true do 

                post admin_create_users_path,{user: {:email => "rrphotosoft@gmail.com", :first_name => "Bhargav", :last_name => "Raut", :date_of_birth => "10/10/1888", :sex => "Male", :title => "Dr"},:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @admin_headers
                
                user_created = assigns(:auth_user)
                expect(user_created).not_to be_nil
                expect(user_created.errors).to be_empty
                expect(user_created.first_name).to eq("Bhargav")
                expect(user_created.last_name).to eq("Raut")
                expect(user_created.date_of_birth).to eq(Time.find_zone("UTC").parse("10/10/1888"))
                expect(user_created.sex).to eq("Male")
                expect(user_created.title).to eq("Dr")
                expect(response.code).to eq("201")
                response_body = JSON.parse(response.body)
                expect(response_body).to eq({"nothing" => true})
                ## now also check the confirmation email is sent.
                confirmation_token = get_confirmation_token_from_email
                expect(confirmation_token).not_to be_nil

            end

            it " -- creates the user and sends the confirmation email -- " do 

                post admin_create_users_path,{user: {:email => "rrphotosoft@gmail.com"},:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @admin_headers
                
                user_created = assigns(:auth_user)
                expect(user_created).not_to be_nil
                expect(user_created.errors).to be_empty
                expect(response.code).to eq("201")
                response_body = JSON.parse(response.body)
                expect(response_body).to eq({"nothing" => true})
                ## now also check the confirmation email is sent.
                confirmation_token = get_confirmation_token_from_email
                expect(confirmation_token).not_to be_nil

            end

            it " -- resends the confirmation email if necessary -- " do 

                ## for this we have to do what?
                user_created = create_user_with_email
                initial_confirmation_token = get_confirmation_token_from_email
               
                initial_email_count = ActionMailer::Base.deliveries.size
                post user_confirmation_path,{user:{email: user_created.email}, api_key: @ap_key,:current_app_id => "testappid"}.to_json,{ "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
                
                new_confirmation_token = get_confirmation_token_from_email
                
                final_email_count = ActionMailer::Base.deliveries.size
                expect(new_confirmation_token).not_to be_nil
                expect(final_email_count - initial_email_count).to eq(1)
                ## now we should be able to get the confirmation token again in the email.


            end

            it " -- sends the password reset instructions on confirmation -- ", :issu => true do 

                ## first get the token, then send it to the confirmations path, and expect the reset password instructions to be sent, as a notification.
                user_created = create_user_with_email
                confirmation_token = get_confirmation_token_from_email
                get user_confirmation_path,{confirmation_token: confirmation_token, api_key: @ap_key, :current_app_id => "testappid"},{ "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
               
                user_created = User.find(user_created.id.to_s)
                ## it will send the reset password email, check the emails.
                reset_password_token = get_reset_password_token_from_email
                expect(reset_password_token).not_to be_nil
            end



            it " -- resends the password reset instructions if necessary -- " do 

                user_created = create_user_with_email
                
                verify_user_email(user_created)

                reset_password_token = get_reset_password_token_from_email

                expect(reset_password_token).not_to be_nil

                req = {:id => user_created.id.to_s, :user => {:created_by_admin => true}, :resource => "users", api_key: @ap_key, :current_app_id => "testappid"}

                put profile_path({:id => user_created.id.to_s}),req.to_json,@admin_headers

                expect(response.code).to eq("204")
                
                latter_reset_password_token = get_reset_password_token_from_email
                
                expect(latter_reset_password_token).not_to be_nil
                
                expect(reset_password_token).not_to eq(latter_reset_password_token)

            end

            it " -- doesnt send the password reset instructions if the confirmation token is invalid -- " do 

                user_created = create_user_with_email
                    
                # visit the confirmation link, with a frivolous confirmation token.
                get user_confirmation_path,{confirmation_token: "the sandman was looking for a legend for a girl", api_key: @ap_key, :current_app_id => "testappid"},{ "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}

                latter_reset_password_token = get_reset_password_token_from_email

                expect(latter_reset_password_token).to be_nil

                
            end

            it " -- doesnt send the password reset instructions if the user changes his email later -- " do 

                ## create the user
                user_created = create_user_with_email

                ## verify his email
                verify_user_email(user_created)

                ## get the reset password token.
                reset_password_token = get_reset_password_token_from_email
                
                ## then change his email
                update_user_email(user_created)

                ## now trying to get the reset password token should result in null, because there is now a confirmation email being sent.
                confirmation_token = get_confirmation_token_from_email
                expect(confirmation_token).not_to be_nil

                ## but the email sent out immediately before this should be the first reset password email sent.
                former_reset_password_token = get_reset_password_token_from_email(-2)

                expect(reset_password_token).to eq(former_reset_password_token)

            end


        end

        context " -- validations --" do 
            it " -- admin can simultaneously create user with email and mobile -- ", :simultaneous_email_password => true do 

                post admin_create_users_path,{user: {:additional_login_param => "9561137096", :email => "bhargav.r.raut@gmail.com"},:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @admin_headers

                message = ActionMailer::Base.deliveries[-1] unless ActionMailer::Base.deliveries.blank?
                
                expect(message).not_to be_blank

                expect(response.code).to eq("201")

            end

        end

        context " -- user with email and mobile -- ", :simult => true do 

            it " -- on verifying the email, a reset password link is sent by email, thereafter mobile can be verified, but reset password link is not sent again. -- ", :simult_email_sms_verify => true do 

                
                pwd = SecureRandom.hex(24)
                
                attributes_for_user = {:email => Faker::Internet.email, :additional_login_param => "9561137096", :password => pwd, :password_confirmation => pwd, :created_by_admin => true}
                user = User.new(attributes_for_user)
                
                user.save
                
                ## a confirmation email should have been sent.
                message = ActionMailer::Base.deliveries[-1].to_s
                confirmation_token = nil
                message.scan(/confirmation_token=(?<confirmation_token>.*)\"/) do |ll|

                    j = Regexp.last_match
                    confirmation_token = j[:confirmation_token]

                end

                expect(confirmation_token).not_to be_nil
                
                get user_confirmation_path,{confirmation_token: confirmation_token}

                ## on confirming it should generate a reset_password_message.
                ## get the base deliveries.
                message = ActionMailer::Base.deliveries[-1].to_s
                confirmation_token = nil
                expect(message =~ /reset_password/).to be_truthy


                @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first

                
                
                $otp_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
                

                @last_user_created.verify_sms_otp($otp_session_id)

                ## this should send the reset password message.

                @last_user_created = User.find(@last_user_created.id.to_s)
               
                expect(@last_user_created.additional_login_param_confirmed?).to be_truthy
         
                resource_ids = JSON.generate({User.name => [@last_user_created.id.to_s]})
                
                n = Noti.where(:resource_ids => resource_ids).first
                
                expect(n).to be_nil
                
            end


            it " -- on verifying the mobile, a reset password link is sent by mobile, thereafter email can be verified, but the reset password link is not resent -- ", :simult_two => true do 

                u = User.where(:additional_login_param => "9561137096").first.delete

                ActionMailer::Base.deliveries = []


                pwd = SecureRandom.hex(24)
                
                attributes_for_user = {:email => Faker::Internet.email, :additional_login_param => "9561137096", :password => pwd, :password_confirmation => pwd, :created_by_admin => true}

                user = User.new(attributes_for_user)
                
                user.save

                @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first

                
                
                $otp_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
                

                @last_user_created.verify_sms_otp($otp_session_id)

                ## this should send the reset password message.

                @last_user_created = User.find(@last_user_created.id.to_s)
               

                expect(@last_user_created.additional_login_param_confirmed?).to be_truthy

                    
                resource_ids = JSON.generate({User.name => [@last_user_created.id.to_s]})
                
                n = Noti.where(:resource_ids => resource_ids).first

                expect(n).not_to be_nil

                ## so the reset password message was sent.
                ## now we try to verify the email.
                ## and then a reset password message should not be 
                ## sent at that time.
                message = ActionMailer::Base.deliveries[-1].to_s
                #puts "the message becomes:"
                #puts message.to_s
                confirmation_token = nil
                message.scan(/confirmation_token=(?<confirmation_token>.*)\"/) do |ll|

                    j = Regexp.last_match
                    confirmation_token = j[:confirmation_token]

                end

                expect(confirmation_token).not_to be_nil
                    
                ActionMailer::Base.deliveries = []

                get user_confirmation_path,{confirmation_token: confirmation_token}

                ## clear the base deliveries.
                ## on confirming it should generate a reset_password_message.
                ## get the base deliveries.
                #message = ActionMailer::Base.deliveries[-1].to_s
                #confirmation_token = nil
                #expect(message =~ /reset_password/).not_to be_truthy
                expect(ActionMailer::Base.deliveries).to be_blank
            end     


          

        end

    end

end