class Auth::AssembliesController < Auth::ApplicationController
  ## only these actions need an authenticated user to be present for them to be executed.
  CONDITIONS_FOR_TOKEN_AUTH = [:create,:update,:destroy,:edit,:new,:index]
  TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
  include Auth::Concerns::DeviseConcern
  include Auth::Concerns::TokenConcern
  before_filter :do_before_request , TCONDITIONS
  before_filter :initialize_vars , TCONDITIONS
  before_filter :is_admin_user , :only => CONDITIONS_FOR_TOKEN_AUTH

  ## all these should be included into the 

  before_filter(:only => [:create,:update]) {|c| @assembly =  c.add_owner_and_signed_in_resource(@assembly)}
  before_filter(:only => [:create]) {|c| c.check_for_create @assembly}
  before_filter(:only => [:update]) {|c| c.check_for_update @assembly}
  before_filter(:only => [:destroy]) {|c| c.check_for_destroy @assembly}


  def initialize_vars
      @assembly_params = permitted_params
      @assembly = @assembly_params[:id] ? Auth::Workflow::Assembly.find_self(@assembly_params[:id],current_signed_in_resource) : Auth::Workflow::Assembly.new(@assembly_params[:assembly])
  end


  # GET /auth/assemblies
  def index
    @assemblies = Auth::Workflow::Assembly.all
    respond_to do |format|
      format.json do 
        render json: @assemblies.to_json
      end
    end
  end

  # GET /auth/assemblies/1
  def show
    respond_to do |format|
      format.json do 
        render json: @assemblies.to_json
      end
    end
  end

  # GET /auth/assemblies/new
  def new
    #@auth_assembly = Auth::Assembly.new
  end

  # GET /auth/assemblies/1/edit
  def edit
  end

  # POST /auth/assemblies
  def create
    respond_to do |format|
      if @assembly.save
        format.json do 
          render json: @assembly.to_json, status: 201
        end
      else
        format.json do 
          render json: {
            id: @assembly.id.to_s,
            errors: @assembly.errors
          }.to_json
        end
      end
    end
  end

  # PATCH/PUT /auth/assemblies/1
  def update
    respond_to do |format|
      if @assembly.save
        format.json do 
          render :nothing => true, :status => 204
        end
      else
        format.json do 
          render json: {
            id: @assembly.id.to_s,
            errors: @assembly.errors
          }.to_json
        end
      end
    end
  end

  # DELETE /auth/assemblies/1
  def destroy
    respond_to do |format|
      if @assembly.destroy
        format.json do 
          render :nothing => true, :status => 204
        end
      else
        format.json do 
          render json: {
            id: @assembly.id.to_s,
            errors: @assembly.errors
          }.to_json
        end
      end
    end
  end

  private
      


    def permitted_params
      puts "params are :"
      puts params.to_s
      params.permit({:assembly => [:name,:description]},:id)
    end

end
