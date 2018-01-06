require_dependency "auth/application_controller"
module Auth
  class ClientsController < ApplicationController
 
   
    respond_to :html,:json
    before_action :ensure_json_request  
    #include Auth::Concerns::TokenConcern
    before_action :set_client, only: [:show, :edit, :destroy,:update]

    ##need to check permissions of 

    #def test

    #end

    # GET /clients
    def index
      #@clients = Client.all
      #respond_with @clients
      #redirect_to "http://www.google.com"
      render :nothing => true, :status => 200
    end

    # GET /clients/1
    def show
      respond_with @client
    end

    # GET /clients/new
    def new
      #@client = Client.new
      render :nothing => true, :status => 200
    end

    # GET /clients/1/edit
    def edit
    end

    # POST /clients
    def create
=begin
      @client = Client.new(client_params)
      @client.versioned_create(:user_id => @client.user_id)
      if @client.op_success?
        redirect_to @client, notice: 'Client was successfully created.'
      else
        render :new
      end
=end
      render :nothing => true, :status => 200
    end

    # response code of 204 is ok.
    # anything else means fail.
    # PATCH/PUT /clients/1
    def update
      ##this line ensures that only the redirect urls can be updated, it only considers the redirect_urls as dirty_fields.
      ##puts params.to_s
      @client.redirect_urls = client_params[:redirect_urls]
      if !client_params[:app_ids].nil?
        @client.app_ids << BSON::ObjectId.new.to_s
      end
      @client.versioned_update({"redirect_urls" => 1, "app_ids" => 1})
      respond_with @client
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
        @client = Client.find(params[:id])
        if @client.nil?
          render :nothing => true, :status => 404
        else
          return
        end
      end

      # Only allow a trusted parameter "white list" through.
      def client_params
        params.require(:client).permit({:redirect_urls => []},:user_id,{:app_ids => []})
      end

      def ensure_json_request  
        return if request.format == :json
        render :nothing => true, :status => 406  
      end 

  end
end
