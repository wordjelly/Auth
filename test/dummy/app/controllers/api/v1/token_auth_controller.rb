class Api::V1::TokenAuthController < ApplicationController

	##this is the only line that we need to add
	protect_from_forgery :except => :index 

	include Auth::Concerns::TokenConcern

	def index
		puts "doing index action."
		if current_user
			render json: current_user, status: 200
		else
			render json: {errors: "no current user"}, status: 400
		end

	end

end
