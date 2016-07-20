require "rails_helper"

RSpec.describe "New user creation", :type => :request do

 

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

      #@user = FactoryGirl.create(:user)
      #post_via_redirect user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
      sign_in_as_a_valid_user

      put "/authenticate/users/", :id => @user.id, :user => {:email => Faker::Internet.email, :current_password => 'password'}
      @user_updated = assigns(:user)

      expect(@user_updated.es).to eql(@user.es)
      expect(@user_updated.authentication_token).to eql(@user.authentication_token)
  	
    end

  	it " -- does not change the email salt or auth_token if other user data is updated -- " do 


  	end

    it " -- redirects " do 

    end
	

  end


  context " -- json requests -- " do 




  end
  
end