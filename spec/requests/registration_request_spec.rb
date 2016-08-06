require "rails_helper"

RSpec.describe "New user creation", :type => :request do
  before(:all) do 
    User.delete_all
    Auth::Client.delete_all
  end

  context " -- web app requests -- " do 

    it " -- does not need an api_key in the params -- " do 

        get new_user_registration_path
        @user = assigns(:user)
        expect(@user).not_to be_nil     

    end

    context " -- email salt and auth token generation -- " do 

    	it " -- creates a email_salt and authentication token on user create -- " do 

        
        post user_registration_path, user: attributes_for(:user)
        @user = assigns(:user)
        expect(@user.es).not_to be_nil
        expect(@user.authentication_token).not_to be_nil

    	end

    	it " -- updates the email_salt and authentication token if the user changes his email -- " do 
        
        sign_in_as_a_valid_user

        put "/authenticate/users/", :id => @user.id, :user => {:email => Faker::Internet.email, :current_password => 'password'}
        @user_updated = assigns(:user)

        expect(@user_updated.es).not_to eql(@user.es)
        expect(@user_updated.authentication_token).not_to eql(@user.authentication_token)
    	
      end

    	it " -- does not change the email salt or auth_token if other user data is updated -- " do 

        sign_in_as_a_valid_user

        put "/authenticate/users/", :id => @user.id, :user => {:name => Faker::Name.name}
        
        @user_updated = assigns(:user)
        
        expect(@user_updated.es).to eql(@user.es)
        
        expect(@user_updated.authentication_token).to eql(@user.authentication_token)

    	end

    end

    context " -- client create update on user create update destroy -- " do 

      it " -- creates a client when a user is created -- " do 

        c = Auth::Client.all.count
        post user_registration_path, user: attributes_for(:user)
        c1 = Auth::Client.all.count
        expect(c1-c).to eql(1)

      end

      it " -- does not create client when user is updated -- " do 

        sign_in_as_a_valid_user
        client = Auth::Client.find(@user.id)
        c = Auth::Client.all.count
        put "/authenticate/users/", :id => @user.id, :user => {:email => Faker::Internet.email, :current_password => 'password'}
        c1 = Auth::Client.all.count
        expect(c1-c).to eq(0)
        expect(client).not_to be_nil

      end


      it " -- destroy's client when user is destroyed -- " do 
        post user_registration_path, user: attributes_for(:user)
        @user = assigns(:user)
        c = Auth::Client.all.count
        u = User.all.count
        delete "/authenticate/users", :id => @user.id
        c1 = Auth::Client.all.count
        u1 = User.all.count
        expect(u - u1).to eq(1)
        expect(c - c1).to eq(1)
      end

    end

    context " sets client if api key is correct --- " do 

      before(:each) do 
        ##clear all users
        User.delete_all
        post user_registration_path, user: attributes_for(:user)
        @user = assigns(:user)
        @api_key = Auth::Client.find(@user.id).api_key
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
        
         put "/authenticate/users/", :id => @user.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, :api_key => @api_key
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
          post user_registration_path, user: attributes_for(:user)
          @user = assigns(:user)
          @cli = Auth::Client.find(@user.id)
          @cli.redirect_urls = ["http://www.google.com"]
          @cli.save
          @api_key = @cli.api_key

        end

        context " -- api_key_invalid -- " do 

          it " --(CREATE ACTION) redirects to root path, does not set client or redirect url -- " do 

            post user_registration_path, {user: attributes_for(:user), api_key: "invalid api_key", redirect_url: "http://www.google.com"}
            @user_just_created = assigns(:user)
            @redirect_url = assigns(:redirect_url)
            @client = assigns(:client)
            expect(@redirect_url).to be_nil
            expect(@client).to be_nil
            expect(response).to redirect_to("/")

          end

          it "--(UPDATE ACTION) redirects to root path, does not set client or redirect url" do 

            put "/authenticate/users/", :id => @user.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, :api_key => "invalid api key", redirect_url: "http://www.google.com"
            @user = assigns(:user)
            @redirect_url = assigns(:redirect_url)
            @client = assigns(:client)
            expect(@redirect_url).to be_nil
            expect(@client).to be_nil
            expect(response).to redirect_to("/")

          end


        end

        context "--url in registered urls--" do 
          
          it " -- redirects in create action -- " do 

            post user_registration_path, {user: attributes_for(:user), api_key: @api_key, redirect_url: "http://www.google.com"}
            @user_just_created = assigns(:user)
            @redirect_url = assigns(:redirect_url)
            expect(@redirect_url).to be == "http://www.google.com"
            auth_token = @user_just_created.authentication_token
            es = @user_just_created.es
            expect(response).to redirect_to("http://www.google.com?authentication_token=#{auth_token}&es=#{es}")
          end

          it "--- redirects in put action --- " do 

            put "/authenticate/users/", :id => @user.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, :api_key => @api_key, redirect_url: "http://www.google.com"
            @user = assigns(:user)
            @redirect_url = assigns(:redirect_url)
            expect(@redirect_url).to be == "http://www.google.com"
            auth_token = @user.authentication_token
            es = @user.es
            expect(response).to redirect_to("http://www.google.com?authentication_token=#{auth_token}&es=#{es}")
            
          end

        end

        context " -- url not in reg urls -- " do

          it "---CREATE redirects to default path --- " do 

            post user_registration_path, {user: attributes_for(:user), api_key: @api_key, redirect_url: "http://www.yahoo.com"}
            @user_just_created = assigns(:user)
            @redirect_url = assigns(:redirect_url)
            expect(@redirect_url).to be_nil
            expect(response).to redirect_to("/")

          end

          it "---UPDATE redirects to default path --- " do 

            put "/authenticate/users/", :id => @user.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, :api_key => @api_key, redirect_url: "http://www.yahoo.com"
            @user = assigns(:user)
            @redirect_url = assigns(:redirect_url)
            expect(@redirect_url).to be_nil
            expect(response).to redirect_to("/")

          end

        end

        context " -- no api key -- " do 

          it " --(CREATE ACTION) redirects to root path, does not set client or redirect url -- " do 

            post user_registration_path, {user: attributes_for(:user), redirect_url: "http://www.google.com"}
            @user_just_created = assigns(:user)
            @redirect_url = assigns(:redirect_url)
            @client = assigns(:client)
            expect(@redirect_url).to be_nil
            expect(@client).to be_nil
            expect(response).to redirect_to("/")

          end

          it "--(UPDATE ACTION) redirects to root path, does not set client or redirect url" do 

            put "/authenticate/users/", :id => @user.id, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, redirect_url: "http://www.google.com"
            @user = assigns(:user)
            @redirect_url = assigns(:redirect_url)
            @client = assigns(:client)
            expect(@redirect_url).to be_nil
            expect(@client).to be_nil
            expect(response).to redirect_to("/")

          end

        end

      end

    end
	

  end


  context " -- json requests -- " do 
    
    before(:example) do 
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
        User.delete_all
        u = User.new(attributes_for(:user))
        u.save
        c = Auth::Client.new(:user_id => u.id, :api_key => "test")
        c.versioned_create
        @api_key = c.api_key
    end

    it " -- fails without an api key --- " do 
      get new_user_registration_path,nil,@headers
      @usern = assigns(:user)
      expect(response.code).to eq("401")
    end

    it " -- passes with an api key --- " do 
      get new_user_registration_path,{:api_key => @api_key, :format => :json}
      @usern = assigns(:user)
      expect(@usern).not_to be_nil 
      expect(response.code).to eq("200")
    end



  end
  
end