require "rails_helper"

RSpec.describe "Registration requests", :admin_registration => true, :type => :request do
  before(:all) do 
    Admin.delete_all
    Auth::Client.delete_all
    module Devise

      RegistrationsController.class_eval do

        def sign_up_params
          ##quick hack to make registrations controller accept confirmed_at, because without that there is no way to send in a confirmed admin directly while creating the admin.
          params.require(:admin).permit(
            :email, :password, :password_confirmation,
            :confirmed_at, :redirect_url, :api_key
          )
        end

      end

    end
  end

  context " -- web app requests -- " do 
    
    after(:example) do 
      Admin.delete_all
      Auth::Client.delete_all
    end

    before(:example) do 
      ##YOU MUST CREATE A CLIENT WITH ANOTHER USER FIRST. 
      ##THIS CLIENT WILL HAVE TO GIVE ITSELF A REDIRECT URL.
      ##IT WILL ALSO HAVE TO HAVE A APP_ID, WHICH IT CAN REQUEST, IN THE UPDATE CLIENT REQUEST.
      ##THEN send in the api_key and app_id for this client.
      ##THEN THIS USER WILL HAVE A CLIENT_AUTHENTICATION -> ALONG WITH AN ES FOR THE APP ID THAT THE CLIENT SENT IN.
      ActionController::Base.allow_forgery_protection = false
      Admin.delete_all
      Auth::Client.delete_all
      @u = Admin.new(attributes_for(:admin_confirmed))
      @u.save
      @c = Auth::Client.where(:resource_id => @u.id).first
      @c.api_key = "test"
      @c.redirect_urls = ["http://www.google.com"]
      @c.app_ids << "test_app_id"
      @c.versioned_update
      @ap_key = @c.api_key
      #@headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.es}

    end


    it " -- does not need an api_key in the params -- " do 
        get new_admin_registration_path
        @user = assigns(:admin)
        expect(@user).not_to be_nil
        expect(@user.errors.full_messages).to be_empty     

    end


    context " -- recaptcha ", recaptcha: true do 
      before(:example) do 
        Recaptcha.configuration.skip_verify_env.delete("test")
      end

      after(:example) do 
        Recaptcha.configuration.skip_verify_env << "test"
      end
      it " -- requires recaptcha on create " do 
        ##we add that 
        
        post admin_registration_path, {admin: attributes_for(:admin_confirmed),:api_key => @ap_key, :current_app_id => "test_app_id"}
        expect(response.body).to eq("recaptcha validation error")
      end

      it " -- requires recaptcha on update " do 
        sign_in_as_a_valid_and_confirmed_admin
        put admin_registration_path, :id => @admin.id, :admin => {:email => "dog@gmail.com", :current_password => "password"},:api_key => @ap_key, :current_app_id => "test_app_id"
        expect(response.body).to eq("recaptcha validation error")
      end

    end

    context " -- auth token and client salt creation -- " do 

      it " -- creates client authentication and auth token on admin create -- " do

        post admin_registration_path, {admin: attributes_for(:admin_confirmed),:api_key => @ap_key, :current_app_id => "test_app_id"}
        @admin = assigns(:admin)
        expect(@admin.client_authentication).not_to be_nil
        expect(@admin.client_authentication).not_to be_empty
        expect(@admin.authentication_token).not_to be_nil
        expect(@admin.errors.full_messages).to be_empty
      end

    	it " -- updates the authentication token if the user changes his email, but not the client_authentication -- " do 
        
        sign_in_as_a_valid_and_confirmed_admin

        ##simulate like the user was authenticated using a client.
        ##so that it will set a client authentication.
        cli = Auth::Client.new
        cli.current_app_id = "test_app_id"
        @admin.set_client_authentication(cli)

        ##this client authentication will not change, provided that we use the same api key and same current app id.

        put admin_registration_path, :id => @admin.id, :admin => {:email => "dog@gmail.com", :current_password => "password"},:api_key => @ap_key, :current_app_id => cli.current_app_id
        
        @admin_updated = assigns(:admin)

        @admin_updated.confirm!

        expect(@admin_updated.errors.full_messages).to be_empty  
        expect(@admin_updated.email).not_to eql(@admin.email)  
        expect(@admin_updated.client_authentication[@c.app_ids[0]]).to eql(@admin.client_authentication[@c.app_ids[0]])
        expect(@admin_updated.authentication_token).not_to eql(@admin.authentication_token)
    	expect(@admin_updated.client_authentication[@c.app_ids[0]]).not_to be_nil
        expect(@admin_updated.authentication_token).not_to be_nil

      end


      it " -- does not change the auth_token or client_authentication if other user data is updated -- " do 

        sign_in_as_a_valid_and_confirmed_admin

        name = Faker::Name.name

        put admin_registration_path, :id => @admin.id, :admin => {:name => name, :current_password => "password"}
        
        @admin_updated = assigns(:admin)
        ##here don't need to confirm anything because we are not changing the email.
        expect(@admin_updated.errors.full_messages).to be_empty
        expect(@admin_updated.client_authentication).to eql(@admin.client_authentication)
        expect(@admin_updated.name).to eql(name)
        expect(@admin_updated.authentication_token).to eql(@admin.authentication_token)

      end


    end

    context " -- client create update on user create update destroy -- " do 

      it " -- creates a client when a user is created -- " do 

      
        c = Auth::Client.all.count
        post admin_registration_path, admin: attributes_for(:admin_confirmed)
        c1 = Auth::Client.all.count
        expect(c1-c).to eql(1)

      end

      it " -- does not create client when user is updated -- " do 

        sign_in_as_a_valid_and_confirmed_admin
        client = Auth::Client.find(@admin.id)
        c = Auth::Client.all.count
        put admin_registration_path, :id => @admin.id, :admin => {:email => Faker::Internet.email, :current_password => 'password'}
        c1 = Auth::Client.all.count
        expect(c1-c).to eq(0)
        expect(client).not_to be_nil

      end


      it " -- destroy's client when user is destroyed -- " do 
        #puts "DOING DESTROY TESTS"
        Admin.delete_all
        sign_in_as_a_valid_and_confirmed_admin
        c = Auth::Client.all.count
        u = Admin.all.count
        #puts "DOING DELETE -----------------"
        #puts @user.attributes.to_s
        delete admin_registration_path, :id => @admin.id
        c1 = Auth::Client.all.count
        u1 = Admin.all.count
        #puts "user all count after deleting is: #{u1}"
        expect(u - u1).to eq(1)
        expect(c - c1).to eq(1)
      end

    end

    context " -- sets client if api key and current_app_id match -- ", :current_problem => true do 

      it " new_user_registration_path -- " do 
        get new_admin_registration_path, {:api_key => @ap_key, :current_app_id => "test_app_id"}
        
        expect(session[:client]).not_to be_nil
      end

      it " create user -- " do 
        post admin_registration_path, {admin: attributes_for(:admin), api_key: @ap_key, current_app_id: "test_app_id"}
        
        expect(session[:client]).not_to be_nil

      end


      it " update user -- " do 
         sign_in_as_a_valid_and_confirmed_admin
         put admin_registration_path, :id => @admin.id, :admin => {:email => "rihanna@gmail.com", :current_password => 'password'}, :api_key => @ap_key, :current_app_id => "test_app_id"
         @updated_admin = assigns(:admin)
         expect(session[:client]).not_to be_nil   
      end

      it " destroy user -- " do 

      end

    end

    context "-- redirect url provided --" do 

      context " -- api key provided -- " do

        context " -- api key invalid -- " do 

          it " --(CREATE ACTION) redirects to root path, does not set client or redirect url, but successfully creates the user, only the redirect fails. -- " do 

            post admin_registration_path, {admin: attributes_for(:admin), api_key: "invalid api_key", redirect_url: "http://www.google.com", current_app_id: "test_app_id"}
            @admin_just_created = assigns(:admin)
            expect(response).to redirect_to(root_path)

          end

          it "--(UPDATE ACTION) redirects to root path, does not set client or redirect url," do 
            sign_in_as_a_valid_and_confirmed_admin
            put admin_registration_path, :id => @admin.id, :admin => {:password => "dogisdead", :current_password => 'password'}, :api_key => "invalid api key", redirect_url: "http://www.google.com" , current_app_id: "test_app_id"
            updated_admin = assigns(:admin)
            admin1 = Admin.where(:email => @admin.email).first 
            expect(admin1.valid_password?("dogisdead")).to eq(true)
            expect(response).to redirect_to(root_path)
          end

        end

        context " -- api key valid -- " do 

          context " -- redirect url invalid -- " do 

            it "---CREATE redirects to default path --- " do 

              post admin_registration_path, {admin: attributes_for(:admin), api_key: @ap_key, redirect_url: "http://www.yahoo.com", current_app_id: "test_app_id"}
                
              @admin_just_created = assigns(:admin)
              expect(session[:client]).not_to be_nil
              expect(response).to redirect_to(root_path)

            end

            it "---UPDATE redirects to default path --- " do 
              
              sign_in_as_a_valid_and_confirmed_admin
              
              put admin_registration_path, :id => @admin.id, :admin => {:email => "rihanna@gmail.com", :current_password => 'password'}, :api_key => @ap_key, redirect_url: "http://www.yahoo.com", current_app_id: "test_app_id"
              
              @admin_just_updated = assigns(:admin)
              expect(session[:client]).not_to be_nil
              expect(response).to redirect_to(root_path)

            end

          end

          context " -- redirect url valid -- " do 

            it " -- redirects in create action -- " do 

              post admin_registration_path, {admin: attributes_for(:admin_confirmed), api_key: @ap_key, redirect_url: "http://www.google.com", current_app_id: "test_app_id"}
              @admin_just_created = assigns(:admin)
              
              
              auth_token = @admin_just_created.authentication_token
              es = @admin_just_created.client_authentication["test_app_id"]
              
              expect(response).to redirect_to("http://www.google.com?authentication_token=#{auth_token}&es=#{es}")
            
            end

            it "--- redirects in put action --- " do 
              
              sign_in_as_a_valid_and_confirmed_admin
              put admin_registration_path, :id => @admin.id, :admin => {:password => "dogisdead", :current_password => 'password'}, :api_key => @ap_key, redirect_url: "http://www.google.com", current_app_id: "test_app_id"
              @admin_just_updated = assigns(:admin)
              
              auth_token = @admin_just_updated.authentication_token
              es = @admin_just_updated.client_authentication["test_app_id"]
              expect(response).to redirect_to("http://www.google.com?authentication_token=#{auth_token}&es=#{es}")
              
            end

          end

        end

      end

    end

  end

  	context " -- json requests -- " do 

    after(:example) do 
      Admin.delete_all
      Auth::Client.delete_all
    end

    before(:example) do 
        ActionController::Base.allow_forgery_protection = true
        Admin.delete_all
        Auth::Client.delete_all
        @u = Admin.new(attributes_for(:admin_confirmed))
        @u.save
        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["test_app_id"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["test_app_id"] = "test_es_token"
        @u.save
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-Admin-Token" => @u.authentication_token, "X-Admin-Es" => @u.client_authentication["test_app_id"], "X-Admin-Aid" => "test_app_id"}
    end

    context " -- fails without an api key --- " do
      it " - READ - " do  
        get new_admin_registration_path,nil,@headers
        expect(response.code).to eq("401")
      end

      it " - CREATE - " do 
        post admin_registration_path, {admin: attributes_for(:admin)}.to_json, @headers
        expect(response.code).to eq("401")
      end

      it " - UPDATE - " do 
        a = {:id => @u.id, :admin => {:email => "rihanna@gmail.com", :current_password => 'password'}}
        put admin_registration_path, a.to_json,@headers
        expect(response.code).to eq("401")
      end

      it " - DESTROY - " do 
        a = {:id => @u.id}
        delete admin_registration_path, a.to_json, @headers
        expect(response.code).to eq("401")
      end

    end

    context " -- invalid api key -- " do 
          it " - READ - " do  
            get new_admin_registration_path,{api_key: "doggy"},@headers
            expect(response.code).to eq("401")
          end

          it " - CREATE - " do 
            post admin_registration_path, {admin: attributes_for(:admin), api_key: "doggy"}.to_json, @headers
            expect(response.code).to eq("401")
          end

          it " - UPDATE - " do 
            a = {:id => @u.id, :admin => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: "doggy"}
            put admin_registration_path, a.to_json,@headers
            expect(response.code).to eq("401")
          end

          it " - DESTROY - " do 
            a = {:id => @u.id, api_key: "dogy"}
            delete admin_registration_path, a.to_json, @headers
            expect(response.code).to eq("401")
          end
      
    end
   

    context " -- api key -- " do 

      context " -- valid api key -- " do 
        
        it " -- CREATE UNCONFIRMED EMAIL ACCOUNT - does not return auth_token and es ", :now => true do 
            post admin_registration_path, {admin: attributes_for(:admin),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
            @admin_created = assigns(:admin)
           
            admin_json_hash = JSON.parse(response.body)
            expect(admin_json_hash.keys).to match_array(["nothing"])
        end        

        it " -- CREATE CONFIRMED EMAIL ACCOUNT - returns the auth token and es -- ", :nowie => true do  
            post admin_registration_path, {admin: attributes_for(:admin_confirmed),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
            @admin_created = assigns(:admin)
            
            admin_json_hash = JSON.parse(response.body)
            expect(admin_json_hash.keys).to match_array(["authentication_token","es"])
            expect(session[:client]).not_to be_nil
            expect(@admin_created).not_to be_nil
            expect(response.code).to eq("200")
        end
 
        context " -- recaptcha ", recaptcha_json: true do 
          before(:example) do 
            Recaptcha.configuration.skip_verify_env.delete("test")
          end

          after(:example) do 
            Recaptcha.configuration.skip_verify_env << "test"
          end

          it " -- json request without android header passes, because it simply returns true from the check_recaptcha def -- " do 

            post admin_registration_path, {admin: attributes_for(:admin_confirmed),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
            resp = JSON.parse(response.body)
            expect(resp.keys).to match_array(["authentication_token","es"])

          end

          ##basically here , it fails because since android os header is there, the verify recaptcha is still run.
          ##it also uses the android_secret_key, but I couldnt figure out how to test for that, tried expect.to have_recevied, but the controller does not receive the verify_recaptcha method, guess not significantly well versed in rspec to know how to test for that.
          it " -- json request with android header will fail, because verify recaptcha fails. "  do 
            @headers["OS-ANDROID"] = true
            
            post admin_registration_path, {admin: attributes_for(:admin_confirmed),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
            #puts response.body.to_s
            resp = JSON.parse(response.body)
            expect(resp["errors"]).to eq("recaptcha validation error")            
          end

        end
        

        context " --- UPDATE REQUEST --- " do 
            
          it " -- works -- " do  
            a = {:id => @u.id, :admin => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "test_app_id"}
          
            put admin_registration_path, a.to_json,@headers
            @admin_updated = assigns(:admin)
            
            expect(session[:client]).not_to be_nil
            expect(@admin_updated).not_to be_nil
            expect(response.code).to eq("200")

          end

          it " -- doesnt respect redirects --- " do 
            a = {:id => @u.id, :admin => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: @ap_key, redirect_url: "http://www.google.com", :current_app_id => "test_app_id"}
          
            put admin_registration_path, a.to_json,@headers
            @admin_updated = assigns(:admin)
            
            expect(session[:client]).not_to be_nil
            expect(session[:redirect_url]).to be_nil
            expect(response.code).to eq("200")


          end
          

        end


        it " --- DESTROY REQUEST --- " do 

         
          a = {:id => @u.id, :api_key => @ap_key, :current_app_id => "test_app_id"}
          delete admin_registration_path(format: :json), a.to_json, @headers
          expect(response.code).to eq("200")

        end

      end

     

    end
  end

  context " -- multiple clients -- " do 
    
    before(:example) do 
    
      ActionController::Base.allow_forgery_protection = false
      @u1 = Admin.new(attributes_for(:admin_confirmed))
      @u1.save
      @c1 = Auth::Client.new(:resource_id => @u1.id, :api_key => "test1")
      @c1.redirect_urls = ["http://www.google.com"]
      @c1.app_ids << "test_app_id1"
      @c1.versioned_create
      @ap_key1 = @c1.api_key

      ###now create the other client.
      @u2 = Admin.new(attributes_for(:admin_confirmed))
      @u2.save
      @c2 = Auth::Client.new(:resource_id => @u2.id, :api_key => "test2")
      @c2.redirect_urls = ["http://www.google.com"]
      @c2.app_ids << "test_app_id2"
      @c2.versioned_create
      @ap_key2 = @c2.api_key
    
    end

    it " -- creates a admin with one client -- " do 

      ##now post to the admin_registration_path using each of these seperately.
       c1_admin_attribs = attributes_for(:admin_confirmed)
       post admin_registration_path, {admin: c1_admin_attribs, api_key: @ap_key1, current_app_id: @c1.app_ids[0]}
       @admin_created_by_first_client = Admin.where(:email => c1_admin_attribs[:email]).first
       expect(@admin_created_by_first_client.client_authentication).not_to be_nil
       expect(@admin_created_by_first_client.client_authentication).not_to be_empty
       expect(@admin_created_by_first_client.authentication_token).not_to be_nil
       expect(@admin_created_by_first_client.errors.full_messages).to be_empty

    end

    it " -- creates a admin with the other client -- " do 

       ##now post to the admin_registration_path using each of these seperately.
       c2_admin_attribs = attributes_for(:admin_confirmed)
       post admin_registration_path, {admin: c2_admin_attribs, api_key: @ap_key2, current_app_id: @c2.app_ids[0]}
       @admin_created_by_second_client = Admin.where(:email => c2_admin_attribs[:email]).first
       expect(@admin_created_by_second_client.client_authentication).not_to be_nil
       expect(@admin_created_by_second_client.client_authentication).not_to be_empty
       expect(@admin_created_by_second_client.authentication_token).not_to be_nil
       expect(@admin_created_by_second_client.errors.full_messages).to be_empty


    end

  end

  context " -- one client , multiple app ids -- " do 
    
    before(:all) do 
      Admin.delete_all
      Auth::Client.delete_all
    end

    before(:example) do 
      ActionController::Base.allow_forgery_protection = false
      @u1 = Admin.new(attributes_for(:admin_confirmed))
      @u1.save
      @c1 = Auth::Client.new(:resource_id => @u1.id, :api_key => "test1")
      @c1.redirect_urls = ["http://www.google.com"]
      @c1.app_ids << "test_app_id1"
      @c1.app_ids << "test_app_id2"
      @c1.versioned_create
      @ap_key1 = @c1.api_key
    
    end

    it " -- creates admin with one app id. -- " do 
      c1_admin_attribs = attributes_for(:admin_confirmed)
      post admin_registration_path, {admin: c1_admin_attribs, api_key: @ap_key1, current_app_id: @c1.app_ids[0]}
      ##expect this admins client_authentication to contain the first app id.
      @usr = assigns(:admin)
      expect(@usr.client_authentication.keys.size).to eql(1)
      expect(@usr.client_authentication["test_app_id1"]).not_to be_nil
    end

    it " -- creates admin with another app id -- " do 
      c1_admin_attribs = attributes_for(:admin_confirmed)
      post admin_registration_path, {admin: c1_admin_attribs, api_key: @ap_key1, current_app_id: @c1.app_ids[1]}
      @usr = assigns(:admin)
      expect(@usr.client_authentication.keys.size).to eql(1)
      expect(@usr.client_authentication["test_app_id2"]).not_to be_nil
    end

  end

end

