class Auth::AssembliesController < ApplicationController


  ## only these actions need an authenticated user to be present for them to be executed.
=begin
  CONDITIONS_FOR_TOKEN_AUTH = [:create,:update,:destroy,:edit,:new,:index]
  TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
  include Auth::Concerns::DeviseConcern
  include Auth::Concerns::TokenConcern
  before_filter :do_before_request , TCONDITIONS
  before_filter :initialize_vars , TCONDITIONS
  before_filter :is_admin_user , :only => CONDITIONS_FOR_TOKEN_AUTH
=end  

  def initialize_vars
      @assembly_params = permitted_params
      puts "these are the assembly params"
      puts @assembly_params.to_s
      @assembly = @assembly_param[:id] ? Auth::Workflow::Assembly.find(@assembly_params[:id]) : Auth::Workflow::Assembly.new
  end


  # GET /auth/assemblies
  def index
    #@auth_assemblies = Auth::Assembly.all
  end

  # GET /auth/assemblies/1
  def show
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
=begin
    @auth_assembly = Auth::Assembly.new(auth_assembly_params)

    if @auth_assembly.save
      redirect_to @auth_assembly, notice: 'Assembly was successfully created.'
    else
      render :new
    end
=end
  end

  # PATCH/PUT /auth/assemblies/1
  def update
=begin
    if @auth_assembly.update(auth_assembly_params)
      redirect_to @auth_assembly, notice: 'Assembly was successfully updated.'
    else
      render :edit
    end
=end
  end

  # DELETE /auth/assemblies/1
  def destroy
=begin
    @auth_assembly.destroy
    redirect_to auth_assemblies_url, notice: 'Assembly was successfully destroyed.'
=end
  end

  private
    

    ## possible actions required
    ## so we have to design actions for each of these eventualities.

    ## => add_stage(s)
    ## => remove_stage(s)
    ## => add sop to stage
    ## => remove sop from stage
    ## => modify sop 
    ## => add step to sop
    ## => remove step from sop
    ## => modify step
    def permitted_params
      params.permit({:add_stage_ids => []},{:remove_stage_ids => []},{:sop => [:_id,:stage_id,:name,{:steps => [:_id,:name]},:add_remove_modify]},{:step => [:_id,:sop_id,:name,:add_remove_modify]})
    end

    

end
