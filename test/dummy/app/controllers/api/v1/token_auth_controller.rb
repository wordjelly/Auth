class Api::V1::TokenAuthController < ApplicationController

	##this is the only line that we need to add
	protect_from_forgery :except => :index 

	include Auth::Concerns::TokenConcern

	def index
		puts "current user is found"
		puts current_user
	end

end
