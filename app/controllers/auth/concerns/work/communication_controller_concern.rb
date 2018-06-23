module Auth::Concerns::Work::InstructionControllerConcern

  	extend ActiveSupport::Concern

  	included do
    	include Auth::Work::Instructions::InstructionsHelper
  	end

  	## at this stage all we will have is instantiations .
  	def get_parent_object(parent_object_class,parent_object_id)

      parent_object = nil

      begin
        parent_object = parent_object_class.constantize.find(parent_object_id)
        if params[:id]
          @auth_work_communication = parent_object.communications.select{|c|
                c.id.to_s == params[:id]
          }
          @auth_work_communication = @auth_work_communication.size > 0 ? @auth_work_communication[0] : Auth::Work::Communication.new(@auth_work_communication_params)
        else

        end
      rescue Mongoid::Errors::DocumentNotFound
        parent_object = parent_object_class.constantize.new
        @auth_work_communication = Auth::Work::Communication.new(@auth_work_communication_params)
      end

      parent_object

  	end

  	def initialize_vars

      instantiate_work_classes
      
      @auth_work_communication_params = permitted_params.fetch(:communication,{})

      @auth_work_cycle = nil

      @auth_work_instruction = nil

      if @auth_work_communication_params[:cycle_id]
          @auth_work_cycle = get_parent_object(@auth_work_cycle_class,@auth_work_communication_params[:cycle_id])
      elsif @auth_work_communication_params[:instruction_id]
          @auth_work_instruction = get_parent_object(@auth_work_instruction_class,@auth_work_communication_params[:instruction_id])
      else
          not_found("please provide a cycle id or an instruction id")
      end      

    end

    def create

    end

    def new
      ## now new has to render this form.
      ## and it has to determine the url and the 
    end

    def index

    end

    def update

    end

    def show

    end

    def destroy

    end

	  def permitted_params
	  	pr = params.permit({:communication => [:send_email,:email_template_path,:method_to_determine_recipients,:repeat,:repeat_times,:method_to_determine_communication_timing,:enqueue_at_time]}, :id, :instruction_id,:cycle_id)
	  end

end