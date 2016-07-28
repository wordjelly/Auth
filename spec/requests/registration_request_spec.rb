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




    context " sets client if api key is correct --- " do 

      it " new_user_registration_path -- " do 

          #get new_user_registration_path, {:api_key => }

      end

      it " create user -- " do 


      end


      it " update user -- " do 



      end


      it " destroy user -- " do 



      end



    end


    context "-- redirect url provided --" do 

      context " -- api key provided -- " do 

        it " -- does not redirect if the api key is invalid -- " do 



        end



        context " -- valid api key -- " do 


          it " -- redirects if the url is in the registered urls -- " do 


          end

          it " -- returns the auth_token and es to the redirect url as params -- " do 

          end

          it " -- does not redirect if the url is not in the registered urls --"  do 

            ##new_user_registration_path
              ##covered in feature specs, the whole cycle.

            ##user_registration_path

            ##user details update

            ##all three paths, with confirmable true.


          end


        end

      end

      it " -- does not redirect if no api key -- " do 

        ##new_user_registration_path
          ##this is covered in the feature specs.
          ##here we only cover the assigning in the request_store.

        ##user_registration_path

        ##user details update

        
      end

    end
	

  end


  context " -- json requests -- " do 




  end
  
end