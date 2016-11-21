require "rails_helper"

RSpec.describe "Registration requests", :type => :request do
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

    before(:example) do 

      ActionController::Base.allow_forgery_protection = false
      User.delete_all
      Auth::Client.delete_all
    
    end

    

    it " -- does not need an api_key in the params -- " do 

        get new_user_registration_path
        @user = assigns(:user)
        expect(@user).not_to be_nil
        expect(@user.errors.full_messages).to be_empty     

    end

    context " -- email salt and auth token generation -- " do 

    	it " -- creates a email_salt and authentication token on user create -- " do 
         ##RESETTING SIGN UP PARAMS, because in admin we had it do require(:admin)
        
        post user_registration_path, user: attributes_for(:user)
        @user = assigns(:user)
        @user.confirm!
        expect(@user.es).not_to be_nil
        expect(@user.authentication_token).not_to be_nil
        expect(@user.errors.full_messages).to be_empty    

    	end

    	it " -- updates the email_salt and authentication token if the user changes his email -- " do 
        
        sign_in_as_a_valid_and_confirmed_user

        put "/authenticate/users/", :id => @user.id, :user => {:email => "dog@gmail.com", :current_password => "password"}
        
        @user_updated = assigns(:user)
        @user_updated.confirm!
        expect(@user_updated.errors.full_messages).to be_empty  
        expect(@user_updated.email).not_to eql(@user.email)  
        expect(@user_updated.es).not_to eql(@user.es)
        expect(@user_updated.authentication_token).not_to eql(@user.authentication_token)
    	
      end

    	it " -- does not change the email salt or auth_token if other user data is updated -- " do 

        sign_in_as_a_valid_and_confirmed_user

        name = Faker::Name.name

        
        put "/authenticate/users/", :id => @user.id, :user => {:name => name, :current_password => "password"}
        
        @user_updated = assigns(:user)
        ##here don't need to confirm anything because we are not changing the email.
        expect(@user_updated.errors.full_messages).to be_empty
        expect(@user_updated.es).to eql(@user.es)
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
        put "/authenticate/users/", :id => @user.id, :user => {:email => Faker::Internet.email, :current_password => 'password'}
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
        delete "/authenticate/users", :id => @user.id
        c1 = Auth::Client.all.count
        u1 = User.all.count
        #puts "user all count after deleting is: #{u1}"
        expect(u - u1).to eq(1)
        expect(c - c1).to eq(1)
      end

    end


    context " sets client if api key is correct --- " do 

      before(:each) do 
        ##clear all users
        User.delete_all
        Auth::Client.delete_all
        @usr = User.new(attributes_for(:user))
        @usr.save
        @c = Auth::Client.new(:resource_id => @usr.id, :api_key => "test")
        @c.versioned_create
        @api_key = @c.api_key
      end

      it " new_user_registration_path -- " do 
        get new_user_registration_path, {:api_key => @api_key}
        @client = assigns(:client)
        expect(@client).not_to be_nil
      end

      it " create user -- " do 

       
        post user_registration_path, {user: attributes_for(:user), api_key: @api_key}
        @client = assigns(:client)
        expect(@client).not_to be_nil

      end


      it " update user -- " do 
         
         sign_in_as_a_valid_and_confirmed_user
         put "/authenticate/users/", :id => @user.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, :api_key => @api_key
         @updated_user = assigns(:user)
         @client = assigns(:client)
         expect(@client).not_to be_nil
         
         
      end


      it " destroy user -- " do 



      end

    end


    context "-- redirect url provided --" do 

      context " -- api key provided -- " do 

        before(:each) do 

          User.delete_all
          Auth::Client.delete_all
          @user = User.new(attributes_for(:user))
          @user.save
          @cli = Auth::Client.new(:resource_id => @user.id, :api_key => "test", :redirect_urls => ["http://www.google.com"])
          @cli.versioned_create
          @api_key = @cli.api_key

        end

        context " -- api_key_invalid -- " do 

          it " --(CREATE ACTION) redirects to root path, does not set client or redirect url, but successfully creates the user, only the redirect fails. -- " do 

            post user_registration_path, {user: attributes_for(:user), api_key: "invalid api_key", redirect_url: "http://www.google.com"}
            
            @user_just_created = assigns(:user)
            expect(response).to redirect_to(root_path)

          end

          it "--(UPDATE ACTION) redirects to root path, does not set client or redirect url," do 
            #puts "--------------PROBLEMATIC TEST------------------"
            
                   
            sign_in_as_a_valid_and_confirmed_user
            #puts "user attributes before updating."
            #puts @user.attributes.to_s
            put "/authenticate/users/", :id => @user.id, :user => {:password => "dogisdead", :current_password => 'password'}, :api_key => "invalid api key", redirect_url: "http://www.google.com"
            #puts response.body.to_s
            updated_user = assigns(:user)
            #puts "error messages "
            #puts updated_user.errors.full_messages.to_s
            #puts updated_user.attributes.to_s
            #puts "------------------PROBLEMATIC TEST ENDS------------"
            ##we now have to see if the new password works or not.
            user1 = User.where(:email => @user.email).first
            #puts "this should be true" 
            expect(user1.valid_password?("dogisdead")).to eq(true)
            expect(response).to redirect_to(root_path)
          end


        end

        context "--url in registered urls--" do 
          
          it " -- redirects in create action -- " do 

            module Devise

              RegistrationsController.class_eval do

                def sign_up_params
                  ##quick hack to make registrations controller accept confirmed_at, because without that there is no way to send in a confirmed user directly while creating the user.
                  params.require(:user).permit(
                    :email, :password, :password_confirmation,
                    :confirmed_at, :redirect_url, :api_key
                  )
                end

              end

            end

            post user_registration_path, {user: attributes_for(:user_confirmed), api_key: @api_key, redirect_url: "http://www.google.com"}
            @user_just_created = assigns(:user)
            @redirect_url = assigns(:redirect_url)
            expect(@redirect_url).to be == "http://www.google.com"
            auth_token = @user_just_created.authentication_token
            es = @user_just_created.es
            expect(response).to redirect_to("http://www.google.com?authentication_token=#{auth_token}&es=#{es}")
          end

          it "--- redirects in put action --- " do 

            
            sign_in_as_a_valid_and_confirmed_user
            put "/authenticate/users/", :id => @user.id, :user => {:password => "dogisdead", :current_password => 'password'}, :api_key => @api_key, redirect_url: "http://www.google.com"
            @user_just_updated = assigns(:user)
            @redirect_url = assigns(:redirect_url)
            expect(@redirect_url).to be == "http://www.google.com"
            auth_token = @user_just_updated.authentication_token
            es = @user_just_updated.es
            expect(response).to redirect_to("http://www.google.com?authentication_token=#{auth_token}&es=#{es}")
            
          end

        end

        context " -- url not in reg urls -- " do

          it "---CREATE redirects to default path --- " do 

            post user_registration_path, {user: attributes_for(:user), api_key: @api_key, redirect_url: "http://www.yahoo.com"}
              
            @user_just_created = assigns(:user)
            @client = assigns(:client)
            expect(@client).not_to be_nil
            expect(response).to redirect_to(root_path)

          end

          it "---UPDATE redirects to default path --- " do 
            

            sign_in_as_a_valid_and_confirmed_user
            
            put "/authenticate/users/", :id => @user.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, :api_key => @api_key, redirect_url: "http://www.yahoo.com"
            
            @user_just_updated = assigns(:user)
            @client = assigns(:client)
            expect(@client).not_to be_nil
            expect(response).to redirect_to(root_path)

          end

        end

        context " -- no api key -- " do 

          it " --(CREATE ACTION) redirects to root path, does not set client or redirect url -- " do 

            post user_registration_path, {user: attributes_for(:user), redirect_url: "http://www.google.com"}
            
            @user_just_created = assigns(:user)
            expect(response).to redirect_to(root_path)

          end

          it "--(UPDATE ACTION) redirects to root path, does not set client or redirect url" do 

            sign_in_as_a_valid_and_confirmed_user

            put "/authenticate/users/", :id => @user.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, redirect_url: "http://www.google.com"
            
            @user_just_updated = assigns(:user)
            expect(response).to redirect_to(root_path)

          end

        end

      end

    end



  end

  context " -- json requests -- " do 


    before(:example) do 
        ActionController::Base.allow_forgery_protection = true
        User.delete_all
        Auth::Client.delete_all
        @u = User.new(attributes_for(:user_confirmed))
        @u.save
        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test")
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.es}
    end

    after(:example) do 
      ActionController::Base.allow_forgery_protection = false
    end


    context " -- fails without an api key --- " do
      it " - READ - " do  
        get new_user_registration_path,nil,@headers
        expect(response.code).to eq("401")
      end

      it " - CREATE - " do 
        post "/authenticate/users", {user: attributes_for(:user)}.to_json, @headers
        expect(response.code).to eq("401")
      end

      it " - UPDATE - " do 
        a = {:id => @u.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}}
        put "/authenticate/users", a.to_json,@headers
        expect(response.code).to eq("401")
      end

      it " - DESTROY - " do 
        a = {:id => @u.id}
        delete "/authenticate/users", a.to_json, @headers
        expect(response.code).to eq("401")
      end

    end

    context " -- invalid api key -- " do 

        

          it " - READ - " do  
            get new_user_registration_path,{api_key: "doggy"},@headers
            expect(response.code).to eq("401")
          end

          it " - CREATE - " do 
            post "/authenticate/users", {user: attributes_for(:user), api_key: "doggy"}.to_json, @headers
            expect(response.code).to eq("401")
          end

          it " - UPDATE - " do 
            a = {:id => @u.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: "doggy"}
            put "/authenticate/users", a.to_json,@headers
            expect(response.code).to eq("401")
          end

          it " - DESTROY - " do 
            a = {:id => @u.id, api_key: "dogy"}
            delete "/authenticate/users", a.to_json, @headers
            expect(response.code).to eq("401")
          end
      
    end
   

    context " -- api key -- " do 

      context " -- valid api key -- " do 
        

        it " -- CREATE REQUEST -- " do 
            post "/authenticate/users", {user: attributes_for(:user_confirmed),:api_key => @ap_key}.to_json, @headers
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
            a = {:id => @u.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: @ap_key}
          
            put "/authenticate/users", a.to_json,@headers
            @user_updated = assigns(:user)
            @cl = assigns(:client)
            expect(@cl).not_to be_nil
            expect(@user_updated).not_to be_nil
            expect(response.code).to eq("204")

          end

          it " -- doesnt respect redirects --- " do 
            a = {:id => @u.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: @ap_key, redirect_url: "http://www.google.com"}
          
            put "/authenticate/users", a.to_json,@headers
            @user_updated = assigns(:user)
            @cl = assigns(:client)
            @red_url = assigns(:redirect_url)
            expect(@cl).not_to be_nil
            expect(@red_url).to be_nil
            expect(response.code).to eq("204")


          end
          

        end


        it " --- DESTROY REQUEST --- " do 

         
          a = {:id => @u.id, :api_key => @ap_key}
          delete "/authenticate/users.json", a.to_json, @headers
          expect(response.code).to eq("204")

        end

      end

     

    end


  end

end
