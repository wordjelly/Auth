require "rails_helper"

RSpec.describe "requirement request spec",:requirement => true, :workflow => true, :type => :request do

	before(:all) do 

		User.delete_all

		## create one non admin user
		@u = User.new(attributes_for(:user_confirmed))
        @u.save
        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["testappid"] = "testestoken"
        @u.save
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["testappid"], "X-User-Aid" => "testappid"}

		## create one admin user.
		@admin = User.new(attributes_for(:admin_confirmed))
        @admin.admin = true
        @admin.client_authentication["testappid"] = "testestoken2"
        @admin.save
        @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @admin.authentication_token, "X-User-Es" => @admin.client_authentication["testappid"], "X-User-Aid" => "testappid"}
		
	end

	context " -- json requests -- " do 

		before(:example) do 
			Auth::Workflow::Assembly.delete_all
		end

		context " -- create -- " do 

			it " -- creates a requirement provided an assembly, stage, sop and step -- " do 



			end



			it " -- loading_inc and multiplying_inc are required while creating/updating a requirement -- " do 

			end


			it " -- validates product id on creating requirement -- " do 

			end

		end


		context " -- show -- " do 

			it " -- defines a function to respond_with required requirement_number and state if called with product ids.(A) -- " do 


			end	

			it  " -- defines a function which first calls (A) and then compares the requirement, with a pre-existing requirment if at all, otherwise then for the availability of a new requirement - and returns a boolean result --  " do 

			end


		end
		

	end


end