require "rails_helper"

RSpec.describe "Registration requests", :reg => true, :type => :request do
  before(:all) do 
    User.delete_all
    Auth::Client.delete_all
    module Devise

      RegistrationsController.class_eval do

        def sign_up_params
          ##quick hack to make registrations controller accept confirmed_at, because without that there is no way to send in a confirmed admin directly while creating the admin.
          params.require(:user).permit(
            :email, :password, :password_confirmation,
            :confirmed_at, :redirect_url, :api_key
          )
        end

      end

    end
  end

  context " -- web app requests -- " do 
    
    after(:example) do 
      User.delete_all
      Auth::Client.delete_all
    end

    before(:example) do 
      ##YOU MUST CREATE A CLIENT WITH ANOTHER USER FIRST. 
      ##THIS CLIENT WILL HAVE TO GIVE ITSELF A REDIRECT URL.
      ##IT WILL ALSO HAVE TO HAVE A APP_ID, WHICH IT CAN REQUEST, IN THE UPDATE CLIENT REQUEST.
      ##THEN send in the api_key and app_id for this client.
      ##THEN THIS USER WILL HAVE A CLIENT_AUTHENTICATION -> ALONG WITH AN ES FOR THE APP ID THAT THE CLIENT SENT IN.
      ActionController::Base.allow_forgery_protection = false
      User.delete_all
      Auth::Client.delete_all
      @u = User.new(attributes_for(:user_confirmed))
      @u.save
      @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test")
      @c.redirect_urls = ["http://www.google.com"]
      @c.app_ids << "test_app_id"
      @c.versioned_create
      @ap_key = @c.api_key
      #@headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.es}

    end


    it " -- does not need an api_key in the params -- " do 
        get new_user_registration_path
        @user = assigns(:user)
        expect(@user).not_to be_nil
        expect(@user.errors.full_messages).to be_empty     

    end


    context " -- auth token and client salt creation -- " do 

      it " -- creates client authentication and auth token on user create -- " do

        post user_registration_path, {user: attributes_for(:user_confirmed), api_key: @ap_key, current_app_id: @c.app_ids[0]}
        @user = assigns(:user)
        expect(@user.client_authentication).not_to be_nil
        expect(@user.client_authentication).not_to be_empty
        expect(@user.authentication_token).not_to be_nil
        expect(@user.errors.full_messages).to be_empty
      end

    	it " -- updates the authentication token if the user changes his email, but not the client_authentication -- " do 
        
        sign_in_as_a_valid_and_confirmed_user

        put user_registration_path, :id => @user.id, :user => {:email => "dog@gmail.com", :current_password => "password"}, :api_key => @ap_key, :current_app_id => @c.app_ids[0]
        
        @user_updated = assigns(:user)
        @user_updated.confirm!

        expect(@user_updated.errors.full_messages).to be_empty  
        expect(@user_updated.email).not_to eql(@user.email)  
        expect(@user_updated.client_authentication[@c.app_ids[0]]).to eql(@user.client_authentication[@c.app_ids[0]])
        expect(@user_updated.authentication_token).not_to eql(@user.authentication_token)
    	  expect(@user_updated.client_authentication[@c.app_ids[0]]).not_to be_nil
        expect(@user_updated.authentication_token).not_to be_nil

      end


      it " -- does not change the auth_token or client_authentication if other user data is updated -- " do 

        sign_in_as_a_valid_and_confirmed_user

        name = Faker::Name.name

        put user_registration_path, :id => @user.id, :user => {:name => name, :current_password => "password"}
        
        @user_updated = assigns(:user)
        ##here don't need to confirm anything because we are not changing the email.
        expect(@user_updated.errors.full_messages).to be_empty
        expect(@user_updated.client_authentication).to eql(@user.client_authentication)
        expect(@user_updated.name).to eql(name)
        expect(@user_updated.authentication_token).to eql(@user.authentication_token)

      end


    end

    context " -- client create update on user create update destroy -- " do 

      it " -- creates a client when a user is created -- " do 

      
        c = Auth::Client.all.count
        post user_registration_path, user: attributes_for(:user_confirmed)
        c1 = Auth::Client.all.count
        expect(c1-c).to eql(1)

      end

      it " -- does not create client when user is updated -- " do 

        sign_in_as_a_valid_and_confirmed_user
        client = Auth::Client.find(@user.id)
        c = Auth::Client.all.count
        put user_registration_path, :id => @user.id, :user => {:email => Faker::Internet.email, :current_password => 'password'}
        c1 = Auth::Client.all.count
        expect(c1-c).to eq(0)
        expect(client).not_to be_nil

      end


      it " -- destroy's client when user is destroyed -- " do 
        #puts "DOING DESTROY TESTS"
        User.delete_all
        sign_in_as_a_valid_and_confirmed_user
        c = Auth::Client.all.count
        u = User.all.count
        #puts "DOING DELETE -----------------"
        #puts @user.attributes.to_s
        delete user_registration_path, :id => @user.id
        c1 = Auth::Client.all.count
        u1 = User.all.count
        #puts "user all count after deleting is: #{u1}"
        expect(u - u1).to eq(1)
        expect(c - c1).to eq(1)
      end

    end

    context " -- sets client if api key and current_app_id match -- " do 

      it " new_user_registration_path -- " do 
        get new_user_registration_path, {:api_key => @ap_key, :current_app_id => "test_app_id"}
        @client = assigns(:client)
        expect(@client).not_to be_nil
      end

      it " create user -- " do 
        post user_registration_path, {user: attributes_for(:user), api_key: @ap_key, current_app_id: "test_app_id"}
        @client = assigns(:client)
        expect(@client).not_to be_nil

      end


      it " update user -- " do 
         sign_in_as_a_valid_and_confirmed_user
         put user_registration_path, :id => @user.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, :api_key => @ap_key, :current_app_id => "test_app_id"
         @updated_user = assigns(:user)
         @client = assigns(:client)
         expect(@client).not_to be_nil         
      end

      it " destroy user -- " do 

      end

    end

    context "-- redirect url provided --" do 

      context " -- api key provided -- " do

        context " -- api key invalid -- " do 

          it " --(CREATE ACTION) redirects to root path, does not set client or redirect url, but successfully creates the user, only the redirect fails. -- " do 

            post user_registration_path, {user: attributes_for(:user), api_key: "invalid api_key", redirect_url: "http://www.google.com", current_app_id: "test_app_id"}
            @user_just_created = assigns(:user)
            expect(response).to redirect_to(root_path)

          end

          it "--(UPDATE ACTION) redirects to root path, does not set client or redirect url," do 
            sign_in_as_a_valid_and_confirmed_user
            put user_registration_path, :id => @user.id, :user => {:password => "dogisdead", :current_password => 'password'}, :api_key => "invalid api key", redirect_url: "http://www.google.com" , current_app_id: "test_app_id"
            updated_user = assigns(:user)
            user1 = User.where(:email => @user.email).first 
            expect(user1.valid_password?("dogisdead")).to eq(true)
            expect(response).to redirect_to(root_path)
          end

        end

        context " -- api key valid -- " do 

          context " -- redirect url invalid -- " do 

            it "---CREATE redirects to default path --- " do 

              post user_registration_path, {user: attributes_for(:user), api_key: @ap_key, redirect_url: "http://www.yahoo.com", current_app_id: "test_app_id"}
                
              @user_just_created = assigns(:user)
              @client = assigns(:client)
              expect(@client).not_to be_nil
              expect(response).to redirect_to(root_path)

            end

            it "---UPDATE redirects to default path --- " do 
              
              sign_in_as_a_valid_and_confirmed_user
              
              put user_registration_path, :id => @user.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, :api_key => @ap_key, redirect_url: "http://www.yahoo.com", current_app_id: "test_app_id"
              
              @user_just_updated = assigns(:user)
              @client = assigns(:client)
              expect(@client).not_to be_nil
              expect(response).to redirect_to(root_path)

            end

          end

          context " -- redirect url valid -- " do 

            it " -- redirects in create action -- " do 

              post user_registration_path, {user: attributes_for(:user_confirmed), api_key: @ap_key, redirect_url: "http://www.google.com", current_app_id: "test_app_id"}
              @user_just_created = assigns(:user)
              @redirect_url = assigns(:redirect_url)
              expect(@redirect_url).to be == "http://www.google.com"
              auth_token = @user_just_created.authentication_token
              es = @user_just_created.client_authentication["test_app_id"]
              #es = @user_just_created.es
              #puts response.code.to_s
              expect(response).to redirect_to("http://www.google.com?authentication_token=#{auth_token}&es=#{es}")
            
            end

            it "--- redirects in put action --- " do 
              
              sign_in_as_a_valid_and_confirmed_user
              put user_registration_path, :id => @user.id, :user => {:password => "dogisdead", :current_password => 'password'}, :api_key => @ap_key, redirect_url: "http://www.google.com", current_app_id: "test_app_id"
              @user_just_updated = assigns(:user)
              @redirect_url = assigns(:redirect_url)
              expect(@redirect_url).to be == "http://www.google.com"
              auth_token = @user_just_updated.authentication_token
              es = @user_just_updated.client_authentication["test_app_id"]
              expect(response).to redirect_to("http://www.google.com?authentication_token=#{auth_token}&es=#{es}")
              
            end

          end

        end

      end

    end

  end

  context " -- json requests -- " do 

    after(:example) do 
      User.delete_all
      Auth::Client.delete_all
    end

    before(:example) do 
        ActionController::Base.allow_forgery_protection = true
        User.delete_all
        Auth::Client.delete_all
        @u = User.new(attributes_for(:user_confirmed))
        @u.save
        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["test_app_id"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["test_app_id"] = "test_es_token"
        @u.save
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
    end

    context " -- fails without an api key --- " do
      it " - READ - " do  
        get new_user_registration_path,nil,@headers
        expect(response.code).to eq("401")
      end

      it " - CREATE - " do 
        post user_registration_path, {user: attributes_for(:user)}.to_json, @headers
        expect(response.code).to eq("401")
      end

      it " - UPDATE - " do 
        a = {:id => @u.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}}
        put user_registration_path, a.to_json,@headers
        expect(response.code).to eq("401")
      end

      it " - DESTROY - " do 
        a = {:id => @u.id}
        delete user_registration_path, a.to_json, @headers
        expect(response.code).to eq("401")
      end

    end

    context " -- invalid api key -- " do 
          it " - READ - " do  
            get new_user_registration_path,{api_key: "doggy"},@headers
            expect(response.code).to eq("401")
          end

          it " - CREATE - " do 
            post user_registration_path, {user: attributes_for(:user), api_key: "doggy"}.to_json, @headers
            expect(response.code).to eq("401")
          end

          it " - UPDATE - " do 
            a = {:id => @u.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: "doggy"}
            put user_registration_path, a.to_json,@headers
            expect(response.code).to eq("401")
          end

          it " - DESTROY - " do 
            a = {:id => @u.id, api_key: "dogy"}
            delete user_registration_path, a.to_json, @headers
            expect(response.code).to eq("401")
          end
      
    end
   

    context " -- api key -- " do 

      context " -- valid api key -- " do 
        

        it " -- CREATE REQUEST -- " do 
            post user_registration_path, {user: attributes_for(:user_confirmed),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
            @user_created = assigns(:user)
            @cl = assigns(:client)
            user_json_hash = JSON.parse(response.body)
            expect(user_json_hash.keys).to match_array(["authentication_token","es"])
            expect(@cl).not_to be_nil
            expect(@user_created).not_to be_nil
            expect(response.code).to eq("201")
        end

        

        context " --- UPDATE REQUEST --- " do 
            
          it " -- works -- " do  
            a = {:id => @u.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "test_app_id"}
          
            put user_registration_path, a.to_json,@headers
            @user_updated = assigns(:user)
            @cl = assigns(:client)
            expect(@cl).not_to be_nil
            expect(@user_updated).not_to be_nil
            expect(response.code).to eq("204")

          end

          it " -- doesnt respect redirects --- " do 
            a = {:id => @u.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: @ap_key, redirect_url: "http://www.google.com", :current_app_id => "test_app_id"}
          
            put user_registration_path, a.to_json,@headers
            @user_updated = assigns(:user)
            @cl = assigns(:client)
            @red_url = assigns(:redirect_url)
            expect(@cl).not_to be_nil
            expect(@red_url).to be_nil
            expect(response.code).to eq("204")


          end
          

        end


        it " --- DESTROY REQUEST --- " do 

         
          a = {:id => @u.id, :api_key => @ap_key, :current_app_id => "test_app_id"}
          delete user_registration_path(format: :json), a.to_json, @headers
          expect(response.code).to eq("204")

        end

      end

     

    end
  end

  context " -- multiple clients -- " do 
    
    before(:example) do 
    
      ActionController::Base.allow_forgery_protection = false
      @u1 = User.new(attributes_for(:user_confirmed))
      @u1.save
      @c1 = Auth::Client.new(:resource_id => @u1.id, :api_key => "test1")
      @c1.redirect_urls = ["http://www.google.com"]
      @c1.app_ids << "test_app_id1"
      @c1.versioned_create
      @ap_key1 = @c1.api_key

      ###now create the other client.
      @u2 = User.new(attributes_for(:user_confirmed))
      @u2.save
      @c2 = Auth::Client.new(:resource_id => @u2.id, :api_key => "test2")
      @c2.redirect_urls = ["http://www.google.com"]
      @c2.app_ids << "test_app_id2"
      @c2.versioned_create
      @ap_key2 = @c2.api_key
    
    end

    it " -- creates a user with one client -- " do 

      ##now post to the user_registration_path using each of these seperately.
       c1_user_attribs = attributes_for(:user_confirmed)
       post user_registration_path, {user: c1_user_attribs, api_key: @ap_key1, current_app_id: @c1.app_ids[0]}
       @user_created_by_first_client = User.where(:email => c1_user_attribs[:email]).first
       expect(@user_created_by_first_client.client_authentication).not_to be_nil
       expect(@user_created_by_first_client.client_authentication).not_to be_empty
       expect(@user_created_by_first_client.authentication_token).not_to be_nil
       expect(@user_created_by_first_client.errors.full_messages).to be_empty

    end

    it " -- creates a user with the other client -- " do 

       ##now post to the user_registration_path using each of these seperately.
       c2_user_attribs = attributes_for(:user_confirmed)
       post user_registration_path, {user: c2_user_attribs, api_key: @ap_key2, current_app_id: @c2.app_ids[0]}
       @user_created_by_second_client = User.where(:email => c2_user_attribs[:email]).first
       expect(@user_created_by_second_client.client_authentication).not_to be_nil
       expect(@user_created_by_second_client.client_authentication).not_to be_empty
       expect(@user_created_by_second_client.authentication_token).not_to be_nil
       expect(@user_created_by_second_client.errors.full_messages).to be_empty


    end

  end

  context " -- one client , multiple app ids -- " do 
    
    before(:all) do 
      User.delete_all
      Auth::Client.delete_all
    end

    before(:example) do 
      ActionController::Base.allow_forgery_protection = false
      @u1 = User.new(attributes_for(:user_confirmed))
      @u1.save
      @c1 = Auth::Client.new(:resource_id => @u1.id, :api_key => "test1")
      @c1.redirect_urls = ["http://www.google.com"]
      @c1.app_ids << "test_app_id1"
      @c1.app_ids << "test_app_id2"
      @c1.versioned_create
      @ap_key1 = @c1.api_key
    
    end

    it " -- creates user with one app id. -- " do 
      c1_user_attribs = attributes_for(:user_confirmed)
      post user_registration_path, {user: c1_user_attribs, api_key: @ap_key1, current_app_id: @c1.app_ids[0]}
      ##expect this users client_authentication to contain the first app id.
      @usr = assigns(:user)
      expect(@usr.client_authentication.keys.size).to eql(1)
      expect(@usr.client_authentication["test_app_id1"]).not_to be_nil
    end

    it " -- creates user with another app id -- " do 
      c1_user_attribs = attributes_for(:user_confirmed)
      post user_registration_path, {user: c1_user_attribs, api_key: @ap_key1, current_app_id: @c1.app_ids[1]}
      @usr = assigns(:user)
      expect(@usr.client_authentication.keys.size).to eql(1)
      expect(@usr.client_authentication["test_app_id2"]).not_to be_nil
    end

  end

end
