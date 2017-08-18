require "rails_helper"

RSpec.describe "otp request spec",:otp_request => true, :type => :request do 

	before(:example) do 
		ActionController::Base.allow_forgery_protection = false
      	User.delete_all
      	Auth::Client.delete_all
      	@u = User.new(attributes_for(:user))
      	@u.save
      	##HERE THE USER IS NOT CONFIRMED, SO THE CLIENT IS NOT CREATED IN THE AFTER_sAVE BLOCK.
      	##AS A RESULT WE MANUALLY CREATE A CLIENT.
      	##WE USE THIS SAME CLIENT FOR THE API_KEY AND REDIRECT_URL.
      	##NORMALLY THIS WOULD BE A CLIENT OF ANOTHER USER, ENTIRELY.
      	@c = Auth::Client.new(:resource_id => @u.id)
        @c.api_key = "test"
      	@c.redirect_urls = ["http://www.google.com"]
      	@c.app_ids << "test_app_id"
      	@c.versioned_create
      	@ap_key = @c.api_key	
    end

	after(:example) do 
		User.delete_all
      	Auth::Client.delete_all
	end

  context "--- json requests " do 

    before(:all) do 
      @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
    end

    context "-- forgot password and unlock account" do 

    end

##DO TODAY
    context "-- redirection to redirect url" do 

    end

    context "-- authentication token " do 

    end
##DO TODAY

    context "-- user previously created with oauth " do 

    end

    context "-- returns not found when " do 

      it " -- no resource provided in path " do 

      end

      it " -- resource provided not in configuration " do 

      end

    end

    context "-- validation " do 

      it " -- mobile should be present if no email provided " do 

      end

      it " -- mobile should be unique if changed" do 

      end

      it " -- mobile should obey format if changed" do 

      end

      it " -- email should be present if no mobile is provided " do 

      end

    end

    context "-- on create user with mobile number" do 

        context " -- number valid " do 
      
          it " -- sends otp to mobile number " do 


          end

          it " -- resends otp to mobile number" do 


          end

          it " -- runs verification given otp and mobile number " do 


          end


          it " -- confirms verification given user id" do 


          end
          
          it " -- on updating with email, sends email confirmation " do 


          end

          it " -- saves email on confirming email" do 


          end

          it "-- allows update of mobile, after email confirmed " do 


          end

          it " -- fails to update if mobile and email simultaneously updated " do 

          end

        end

        context " -- number format invalid " do 

          it " -- fails to create user " do 

          end

          it " -- returns not found at send_otp_endpoint " do 

          end

          it " -- returns not found at resend otp endpoint " do 

          end

        end

    end    

    context " -- on create user with email " do 

      context " -- on updating with valid mobile number " do 

        it " -- sends sms otp " do 

        end

        it " -- runs verification " do 

        end

        it " -- verifies and updates additional_login_param_status " do 

        end

        it " -- fails to update if email changed simulataneously " do 

        end

      end

    end

  end

end