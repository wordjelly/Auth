require "rails_helper"

RSpec.describe "Registration requests", :type => :request do
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

    before(:example) do 

      ActionController::Base.allow_forgery_protection = false
      Admin.delete_all
      Auth::Client.delete_all
    
    end

    

    it " -- does not need an api_key in the params -- " do 

        get new_admin_registration_path
        @admin = assigns(:admin)
        expect(@admin).not_to be_nil
        expect(@admin.errors.full_messages).to be_empty     

    end

    context " -- email salt and auth token generation -- " do 

    	it " -- creates a email_salt and authentication token on admin create -- " do 

        
        post admin_registration_path, admin: attributes_for(:admin)
        @admin = assigns(:admin)
        @admin.confirm!
        expect(@admin.es).not_to be_nil
        expect(@admin.authentication_token).not_to be_nil
        expect(@admin.errors.full_messages).to be_empty    

    	end

    	it " -- updates the email_salt and authentication token if the admin changes his email -- " do 
        
        sign_in_as_a_valid_and_confirmed_admin

        put admin_registration_path, :id => @admin.id, :admin => {:email => "dog@gmail.com", :current_password => "password"}
        
        @admin_updated = assigns(:admin)
        @admin_updated.confirm!
        expect(@admin_updated.errors.full_messages).to be_empty  
        expect(@admin_updated.email).not_to eql(@admin.email)  
        expect(@admin_updated.es).not_to eql(@admin.es)
        expect(@admin_updated.authentication_token).not_to eql(@admin.authentication_token)
    	
      end

    	it " -- does not change the email salt or auth_token if other admin data is updated -- " do 

        sign_in_as_a_valid_and_confirmed_admin

        name = Faker::Name.name

        
        put admin_registration_path, :id => @admin.id, :admin => {:name => name, :current_password => "password"}
        
        @admin_updated = assigns(:admin)
        ##here don't need to confirm anything because we are not changing the email.
        expect(@admin_updated.errors.full_messages).to be_empty
        expect(@admin_updated.es).to eql(@admin.es)
        expect(@admin_updated.name).to eql(name)
        expect(@admin_updated.authentication_token).to eql(@admin.authentication_token)

        

    	end

    end

    context " -- client create update on admin create update destroy -- " do 

      it " -- creates a client when a admin is created -- " do 

        c = Auth::Client.all.count
        post admin_registration_path, admin: attributes_for(:admin_confirmed)
        c1 = Auth::Client.all.count
        expect(c1-c).to eql(1)

      end

      it " -- does not create client when admin is updated -- " do 

        sign_in_as_a_valid_and_confirmed_admin
        client = Auth::Client.find(@admin.id)
        c = Auth::Client.all.count
        put admin_registration_path, :id => @admin.id, :admin => {:email => Faker::Internet.email, :current_password => 'password'}
        c1 = Auth::Client.all.count
        expect(c1-c).to eq(0)
        expect(client).not_to be_nil

      end


      it " -- destroy's client when admin is destroyed -- " do 
        #puts "DOING DESTROY TESTS"
        Admin.delete_all
        sign_in_as_a_valid_and_confirmed_admin
        c = Auth::Client.all.count
        u = Admin.all.count
        #puts "DOING DELETE -----------------"
        #puts @admin.attributes.to_s
        delete admin_registration_path, :id => @admin.id
        c1 = Auth::Client.all.count
        u1 = Admin.all.count
        #puts "admin all count after deleting is: #{u1}"
        expect(u - u1).to eq(1)
        expect(c - c1).to eq(1)
      end

    end


    context " sets client if api key is correct --- " do 

      before(:each) do 
        ##clear all admins
        Admin.delete_all
        Auth::Client.delete_all
        @usr = Admin.new(attributes_for(:admin))
        @usr.save
        @c = Auth::Client.new(:resource_id => @usr.id, :api_key => "test")
        @c.versioned_create
        @api_key = @c.api_key
      end

      it " new_admin_registration_path -- " do 
        get new_admin_registration_path, {:api_key => @api_key}
        @client = assigns(:client)
        expect(@client).not_to be_nil
      end

      it " create admin -- " do 

       
        post admin_registration_path, {admin: attributes_for(:admin), api_key: @api_key}
        @client = assigns(:client)
        expect(@client).not_to be_nil

      end


      it " update admin -- " do 
         
         sign_in_as_a_valid_and_confirmed_admin
         put admin_registration_path, :id => @admin.id, :admin => {:email => "rihanna@gmail.com", :current_password => 'password'}, :api_key => @api_key
         @updated_admin = assigns(:admin)
         @client = assigns(:client)
         expect(@client).not_to be_nil
         
         
      end


      it " destroy admin -- " do 



      end

    end


    context "-- redirect url provided --" do 

      context " -- api key provided -- " do 

        before(:each) do 

          Admin.delete_all
          Auth::Client.delete_all
          @admin = Admin.new(attributes_for(:admin))
          @admin.save
          @cli = Auth::Client.new(:resource_id => @admin.id, :api_key => "test", :redirect_urls => ["http://www.google.com"])
          @cli.versioned_create
          @api_key = @cli.api_key

        end

        context " -- api_key_invalid -- " do 

          it " --(CREATE ACTION) redirects to root path, does not set client or redirect url, but successfully creates the admin, only the redirect fails. -- " do 

            post admin_registration_path, {admin: attributes_for(:admin), api_key: "invalid api_key", redirect_url: "http://www.google.com"}
            
            @admin_just_created = assigns(:admin)
            expect(response).to redirect_to(root_path)

          end

          it "--(UPDATE ACTION) redirects to root path, does not set client or redirect url," do 
            #puts "--------------PROBLEMATIC TEST------------------"
            
                   
            sign_in_as_a_valid_and_confirmed_admin
            #puts "admin attributes before updating."
            #puts @admin.attributes.to_s
            put admin_registration_path, :id => @admin.id, :admin => {:password => "dogisdead", :current_password => 'password'}, :api_key => "invalid api key", redirect_url: "http://www.google.com"
            #puts response.body.to_s
            updated_admin = assigns(:admin)
            #puts "error messages "
            #puts updated_admin.errors.full_messages.to_s
            #puts updated_admin.attributes.to_s
            #puts "------------------PROBLEMATIC TEST ENDS------------"
            ##we now have to see if the new password works or not.
            admin1 = Admin.where(:email => @admin.email).first
            #puts "this should be true" 
            expect(admin1.valid_password?("dogisdead")).to eq(true)
            expect(response).to redirect_to(root_path)
          end


        end

        context "--url in registered urls--" do 
          
          it " -- redirects in create action -- " do 

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

            post admin_registration_path, {admin: attributes_for(:admin_confirmed), api_key: @api_key, redirect_url: "http://www.google.com"}
            @admin_just_created = assigns(:admin)
            @redirect_url = assigns(:redirect_url)
            expect(@redirect_url).to be == "http://www.google.com"
            auth_token = @admin_just_created.authentication_token
            es = @admin_just_created.es
            expect(response).to redirect_to("http://www.google.com?authentication_token=#{auth_token}&es=#{es}")
          end

          it "--- redirects in put action --- " do 

            
            sign_in_as_a_valid_and_confirmed_admin
            put admin_registration_path, :id => @admin.id, :admin => {:password => "dogisdead", :current_password => 'password'}, :api_key => @api_key, redirect_url: "http://www.google.com"
            @admin_just_updated = assigns(:admin)
            @redirect_url = assigns(:redirect_url)
            expect(@redirect_url).to be == "http://www.google.com"
            auth_token = @admin_just_updated.authentication_token
            es = @admin_just_updated.es
            expect(response).to redirect_to("http://www.google.com?authentication_token=#{auth_token}&es=#{es}")
            
          end

        end

        context " -- url not in reg urls -- " do

          it "---CREATE redirects to default path --- " do 

            post admin_registration_path, {admin: attributes_for(:admin), api_key: @api_key, redirect_url: "http://www.yahoo.com"}
              
            @admin_just_created = assigns(:admin)
            @client = assigns(:client)
            expect(@client).not_to be_nil
            expect(response).to redirect_to(root_path)

          end

          it "---UPDATE redirects to default path --- " do 
            

            sign_in_as_a_valid_and_confirmed_admin
            
            put admin_registration_path, :id => @admin.id, :admin => {:email => "rihanna@gmail.com", :current_password => 'password'}, :api_key => @api_key, redirect_url: "http://www.yahoo.com"
            
            @admin_just_updated = assigns(:admin)
            @client = assigns(:client)
            expect(@client).not_to be_nil
            expect(response).to redirect_to(root_path)

          end

        end

        context " -- no api key -- " do 

          it " --(CREATE ACTION) redirects to root path, does not set client or redirect url -- " do 

            post admin_registration_path, {admin: attributes_for(:admin), redirect_url: "http://www.google.com"}
            
            @admin_just_created = assigns(:admin)
            expect(response).to redirect_to(root_path)

          end

          it "--(UPDATE ACTION) redirects to root path, does not set client or redirect url" do 

            sign_in_as_a_valid_and_confirmed_admin

            put admin_registration_path, :id => @admin.id, :admin => {:email => "rihanna@gmail.com", :current_password => 'password'}, redirect_url: "http://www.google.com"
            
            @admin_just_updated = assigns(:admin)
            expect(response).to redirect_to(root_path)

          end

        end

      end

    end



  end

  context " -- json requests -- " do 


    before(:example) do 
        ActionController::Base.allow_forgery_protection = true
        Admin.delete_all
        Auth::Client.delete_all
        @u = Admin.new(attributes_for(:admin_confirmed))
        @u.save
        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test")
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-admin-Token" => @u.authentication_token, "X-admin-Es" => @u.es}
    end

    after(:example) do 
      ActionController::Base.allow_forgery_protection = false
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
        

        it " -- CREATE REQUEST -- " do 
            post admin_registration_path, {admin: attributes_for(:admin_confirmed),:api_key => @ap_key}.to_json, @headers
            @admin_created = assigns(:admin)
            @cl = assigns(:client)
            admin_json_hash = JSON.parse(response.body)
            expect(admin_json_hash.keys).to match_array(["authentication_token","es"])
            expect(@cl).not_to be_nil
            expect(@admin_created).not_to be_nil
            expect(response.code).to eq("201")
        end

        

        context " --- UPDATE REQUEST --- " do 
            
          it " -- works -- " do  
            a = {:id => @u.id, :admin => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: @ap_key}
          
            put admin_registration_path, a.to_json,@headers
            @admin_updated = assigns(:admin)
            @cl = assigns(:client)
            expect(@cl).not_to be_nil
            expect(@admin_updated).not_to be_nil
            expect(response.code).to eq("204")

          end

          it " -- doesnt respect redirects --- " do 
            a = {:id => @u.id, :admin => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: @ap_key, redirect_url: "http://www.google.com"}
          
            put admin_registration_path, a.to_json,@headers
            @admin_updated = assigns(:admin)
            @cl = assigns(:client)
            @red_url = assigns(:redirect_url)
            expect(@cl).not_to be_nil
            expect(@red_url).to be_nil
            expect(response.code).to eq("204")


          end
          

        end


        it " --- DESTROY REQUEST --- " do 

         
          a = {:id => @u.id, :api_key => @ap_key}
          delete admin_registration_path(format: :json), a.to_json, @headers
          expect(response.code).to eq("204")

        end

      end

     

    end


  end

end