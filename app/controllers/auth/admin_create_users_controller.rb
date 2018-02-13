class Auth::AdminCreateUsersController < ApplicationController
  ## only these actions need an authenticated user to be present for them to be executed.
  CONDITIONS_FOR_TOKEN_AUTH = [:create,:update,:destroy,:edit,:new,:index,:show]
  TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
  include Auth::Concerns::DeviseConcern
  include Auth::Concerns::TokenConcern
  before_filter :do_before_request , TCONDITIONS
  before_filter :initialize_vars , TCONDITIONS
  ## ensures that only admin users.
  before_filter :is_admin_user , TCONDITIONS


  ## called before all the actions.
  def initialize_vars
    
    @auth_user_class = Auth.configuration.user_class.constantize

    @auth_user_params = permitted_params.fetch(:user,{}) 

    @auth_user = params[:id] ? @auth_user_class.find_self(params[:id],current_signed_in_resource) : @auth_user_class.new(@auth_user_params)
    
  end

  # GET /auth/admin_create_users
  def index
    #@auth_admin_create_users = Auth::AdminCreateUser.all
  end

  # GET /auth/admin_create_users/1
  def show
  end

  # GET /auth/admin_create_users/new
  def new
    # what kind of form should be presented to the admin.

    #@auth_admin_create_user = Auth::AdminCreateUser.new
    ## just render a form with the user model.
  end

  # GET /auth/admin_create_users/1/edit
  def edit
  end

  #  User.where(:email => "bhargav.r.raut@gmail.com").first.delete
  # POST /auth/admin_create_users
  def create
    @auth_user.password = @auth_user.password_confirmation =SecureRandom.hex(24)
    @auth_user.m_client = self.m_client
    @auth_user.created_by_admin = true

    ## we will have to set the m_client.
    ## but what if that client is different from the client that was used to create the user?
    ## no this will not happen here.
    ## here we will only create.
    respond_to do |format|
      if @auth_user.save
        if !@auth_user.additional_login_param.blank?
          format.html {render "auth/confirmations/enter_otp.html.erb"}
          format.json {render json: @auth_user.to_json, status: :created}
        else
          format.html {render "auth/admin_create_users/show.html.erb"}
          format.json {render json: @auth_user.to_json, status: :created}
        end
      else
        format.html {render "new.html.erb"}
        format.json {render json:  {:errors => @auth_user.errors}, status: 422}
      end
    end
  end

  # PATCH/PUT /auth/admin_create_users/1
  def update
    ## should also allow stuff like
    ## resend sms otp
    ## resend confirmation email
  end

  # DELETE /auth/admin_create_users/1
  def destroy
    @auth_admin_create_user.destroy
    redirect_to auth_admin_create_users_url, notice: 'Admin create user was successfully destroyed.'
  end

  def permitted_params
    params.permit({user: [:email,:additional_login_param, :password, :password_confirmation]},:id)    
  end

end
