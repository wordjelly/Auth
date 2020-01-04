module Auth::Concerns::Work::CommunicationControllerConcern

  	extend ActiveSupport::Concern

    def set_instruction
      if product_id = @auth_work_communication_params[:product_id]
        if instruction_id = @auth_work_communication_params[:instruction_id]
          if @auth_shopping_product = Auth.configuration.product_class.constantize.find(product_id)
            @auth_work_instruction = nil
            @instruction_index = 0
            @auth_shopping_product.instructions.each do |inst|
              if inst.id.to_s == instruction_id
                @auth_work_instruction = inst
                break
              end
              @instruction_index+=1
            end
          end
        end
      elsif cart_item_id = @auth_work_communication_params[:cart_item_id]
        if instruction_id = @auth_work_communication_params[:instruction_id]
          if @auth_shopping_cart_item = Auth.configuration.cart_item_class.constantize.find(cart_item_id)
            @auth_work_instruction = nil
            @instruction_index = 0
            @auth_shopping_cart_item.instructions.each do |inst|
              if inst.id.to_s == instruction_id
                @auth_work_instruction = inst
                break
              end
              @instruction_index+=1
            end
          end
        end
      end
    end

    def set_cycle

    end


  	def initialize_vars

      instantiate_work_classes
      
      @auth_work_communication_params = permitted_params.fetch(:communication,{})

      @auth_work_cycle = nil

      @auth_work_instruction = nil

      if @auth_work_communication_params[:cycle_id]
          set_cycle
      elsif @auth_work_communication_params[:instruction_id]
          set_instruction
      else
          not_found("please provide a cycle id or an instruction id")
      end      

      not_found("instruction not found") unless @auth_work_instruction 

      ## if the communication id is found, otherwise instantiate a new communication from the params.
      if params[:id]
        begin
          @auth_work_communication = @auth_work_communication_class.find(params[:id])
        rescue Mongoid::Errors::DocumentNotFound
          @auth_work_communication = @auth_work_communication_class.new(@auth_work_communication_params)  
        end
      else
        @auth_work_communication = @auth_work_communication_class.new(@auth_work_communication_params)
      end


    end

    def create
      if @auth_shopping_product
        @auth_work_instruction.communications << @auth_work_communication
        @auth_shopping_product.instructions[@instruction_index] = @auth_work_instruction
        @auth_shopping_product.save
      end
      respond_to do |format|
        format.html do 
          render "show"
        end
        format.json do 
          render :json => @auth_work_communication.to_json
        end
      end
    end

    def new
      
    end

    def edit

    end

    def index

    end

    def update
      ## now this still needs to be coded but will come to that later.
    end

    def show

    end

    def destroy

    end

	  def permitted_params
	  	pr = params.permit({:communication => [:send_email,:email_template_path,:method_to_determine_recipients,:repeat,:repeat_times,:method_to_determine_communication_timing,:enqueue_at_time,:instruction_id,:cycle_id,:cart_item_id, :product_id, :name, :description]}, :id)
	  end

end