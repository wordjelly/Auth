require_dependency "auth/application_controller"
module Auth
  class ClientsController < ApplicationController
 
    respond_to :html
  
    before_action :authenticate_resource!

    before_action :set_client 

    ## what if the client id is not the same as the user id.
    ## in that case an error should be raised.

    before_action :verify_client_belongs_to_user


    # GET /clients
    def index
      render :nothing => true, :status => 200
    end

    # GET /clients/1
    def show
      respond_with @client
    end

    ## how are we going to get the client id exactly?
    ## that's the basic problem
    ## thereafter we can do the rest.
    

    # GET /clients/new
    def new
      #@client = Client.new
      render :nothing => true, :status => 200
    end

    # GET /clients/1/edit
    def edit
      ## edit should show forms for adding an app id.
      ## design the form.
    end

    # POST /clients
    def create
      render :nothing => true, :status => 200
    end

    # response code of 204 is ok.
    # anything else means fail.
    # PATCH/PUT /clients/1
    def update
      

      @client.redirect_urls << client_params[:add_redirect_url] if client_params[:add_redirect_url]
      
      @client.app_ids << BSON::ObjectId.new.to_s if client_params[:add_app_id]
      
      
      @client.versioned_update({"redirect_urls" => 1, "app_ids" => 1})

      if @client.op_success?
        render "show"
      else
        render "edit"
      end
      
    end

    # response status of 404 or 204 is ok.
    # 404 means client doesnt exist
    # 204 means it was destroyed.
    # DELETE /clients/1
    def destroy
      @client.destroy
      #redirect_to clients_url, notice: 'Client was successfully destroyed.'
      respond_with(status: 200)
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      # the find method is overriden in the model, where it uses the :id (which is actually the user_id, because we have overridden the to_param method to use user_id). 
      def set_client
        @client = Auth::Client.find(params[:id])
        if @client.nil?
          render :nothing => true, :status => 404
        else
          return
        end
      end

      ## if the resource_signed_in is an admin, just return
      ## otherwise if the user's id is not the same as the id passed in, then throw a not_found.
      ## this means that only if the guy is an admin , then this can work.
      ## otherwise it cannot work
      ## i think this has to be done from the web app.
      def verify_client_belongs_to_user
        return if @resource_for_web_app.is_admin?
        not_found("client does not belong to user") if @resource_for_web_app.id.to_s != params[:id]
      end

      # Only allow a trusted parameter "white list" through.
      def client_params
        params.require(:client).permit({:redirect_urls => []},{:app_ids => []}, :add_app_id, :add_redirect_url)
      end

      #def ensure_json_request  
      #  return if request.format == :json
      #  render :nothing => true, :status => 406  
      #end 

  end
end
