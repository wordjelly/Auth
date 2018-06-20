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

	def instantiate_work_classes
		instantiate_instruction_class
		instantiate_bullet_class
		instantiate_product_class
	end
end