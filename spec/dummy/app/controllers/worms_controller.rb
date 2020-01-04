class WormsController < ApplicationController
  before_action :set_worm, only: [:show, :edit, :update, :destroy]

  # GET /worms
  def index
    @worms = Worm.all
  end

  # GET /worms/1
  def show
  end

  # GET /worms/new
  def new
    @worm = Worm.new
  end

  # GET /worms/1/edit
  def edit
  end

  # POST /worms
  def create
    @worm = Worm.new(worm_params)

    if @worm.save
      redirect_to @worm, notice: 'Worm was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /worms/1
  def update
    if @worm.update(worm_params)
      redirect_to @worm, notice: 'Worm was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /worms/1
  def destroy
    @worm.destroy
    redirect_to worms_url, notice: 'Worm was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_worm
      @worm = Worm.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def worm_params
      params[:worm]
    end
end
