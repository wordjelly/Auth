module Auth::Concerns::Work::InstructionControllerConcern

  extend ActiveSupport::Concern



  def initialize_vars
    instantiate_work_classes
    not_found("no product id provided") unless params[:product_id]
   
    @auth_work_instruction_params = permitted_params.fetch(:instruction,{})
    begin
      if @auth_shopping_product = @auth_shopping_product_class.find(params[:product_id])
    
        @auth_shopping_product = @auth_shopping_product_class.find_self(params[:product_id],current_signed_in_resource)
        ## if the instruction id is provided, then it has to exist
        if params[:id]
          @auth_work_instruction = @auth_shopping_product.instructions.select{|c|
            c.id.to_s == params[:id]
          }
          not_found("no such object") if @auth_work_instruction.empty?
          @auth_work_instruction = @auth_work_instruction[0]
        else
          @auth_work_instruction = @auth_work_instruction_class.new(@auth_work_instruction_params)
        end
      end
    rescue Mongoid::Errors::DocumentNotFound
       @auth_shopping_product = @auth_shopping_product_class.new
       @auth_work_instruction = @auth_work_instruction_class.new(@auth_work_instruction_params)
    end

  end

  def get_index
    index = 0
    @auth_shopping_product.instructions.each do |ins|
      break if ins.id.to_s == @auth_work_instruction.id.to_s
      index+=1
    end
    index
  end


  def create
    check_for_create(@auth_work_instruction)
    @auth_shopping_product.instructions << @auth_work_instruction
    @auth_shopping_product.save
    respond_to do |format|
        format.json do 
          render json: @auth_work_instruction.to_json
        end
        format.html do 
          render :partial => "show.html.erb", locals: {instruction: @auth_work_instruction, product: @auth_shopping_product}
        end
    end
  end

  def update
    check_for_update(@auth_work_instruction)
    @auth_work_instruction.assign_attributes(@auth_work_instruction_params)
    @auth_shopping_product.instructions[get_index] = @auth_work_instruction
    @auth_shopping_product.save
    respond_to do |format|
        format.json do 
          render json: @auth_work_instruction.to_json
        end
        format.html do 
          render :partial => "show.html.erb", locals: {instruction: @auth_work_instruction, product: @auth_shopping_product}
        end
    end
  end

  def index
  
  end

  def show
    instantiate_work_classes
    ## so i will have to pass the product id as well.
    @auth_shopping_product = @auth_shopping_product_class.find(params[:product_id])
    @auth_work_instruction = @auth_shopping_product.instructions.select{|c| c.id.to_s == params[:id]}[0]
  end

  def destroy
    check_for_destroy(@auth_work_instruction)
    @auth_shopping_product.delete_at(get_index)
    @auth_shopping_product.save
    respond_with @auth_work_instruction
  end

  def new
    
  end

  def edit

  end

  ## okay so how to port this to the pathofast side ?
  ## we can just package the gem and see how it fares.
  ## that's the best way
  ## the only remaining major issue will be the images
  ## and the only thing that has failed completely is the micro
  ## let me first build the create ?

  def permitted_params
  	pr = params.permit({:instruction => [:title,:description]}, :id, :product_id)
  end

end

