class Auth::Work::WorkController < Auth::ApplicationController
	def instantiate_instruction_class
		if @auth_work_instruction_class = Auth.configuration.instruction_class
	      begin
	        @auth_work_instruction_class = @auth_work_instruction_class.constantize
	      rescue
	        not_found("error instantiating class from instruction class")
	      end
	    else
	      not_found("instruction class not specified in configuration")
	    end
	end

	def instantiate_bullet_class
		if @auth_work_bullet_class = Auth.configuration.bullet_class
	      begin
	        @auth_work_bullet_class = @auth_work_bullet_class.constantize
	      rescue
	        not_found("error instantiating class from bullet class")
	      end
	    else
	      not_found("bullet class not specified in configuration")
	    end
	end

	def instantiate_product_class

		if @auth_shopping_product_class = Auth.configuration.product_class
	      begin
	        @auth_shopping_product_class = @auth_shopping_product_class.constantize
	      rescue => e
	      	puts e.to_s
	        not_found("error instatiating class from product class")
	      end
	    else
	      not_found("product class not specified in configuration")
	    end

	end

	def instantiate_communication_class
		if @auth_work_communication_class = Auth.configuration.communication_class
	      begin
	        @auth_work_communication_class = @auth_work_communication_class.constantize
	      rescue => e
	      	puts e.to_s
	        not_found("error instatiating class from communication class")
	      end
	    else
	      not_found("communication class not specified in configuration")
	    end
	end

	def instantiate_communication_class
		if @auth_work_communication_class = Auth.configuration.communication_class
	      begin
	        @auth_work_communication_class = @auth_work_communication_class.constantize
	      rescue => e
	      	puts e.to_s
	        not_found("error instatiating class from communication class")
	      end
	    else
	      not_found("communication class not specified in configuration")
	    end
	end

	def instantiate_cycle_class
		if @auth_work_cycle_class = Auth.configuration.cycle_class
	      begin
	        @auth_work_cycle_class = @auth_work_cycle_class.constantize
	      rescue => e
	      	puts e.to_s
	        not_found("error instatiating class from cycle class")
	      end
	    else
	      not_found("cycle class not specified in configuration")
	    end
	end
	## do we have a cycle class / controller, obviously are going to need this eventually.
	## so let me now add that to the engine, add cycle class to engine.
	
	def instantiate_work_classes
		instantiate_instruction_class
		instantiate_bullet_class
		instantiate_product_class
		instantiate_cycle_class
		instantiate_communication_class
	end
end