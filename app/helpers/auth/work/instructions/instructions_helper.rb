module Auth::Work::Instructions::InstructionsHelper
    ## get /new
=begin
	def new_instruction_path
      main_app.send(Auth::OmniAuth::Path.new_path(Auth.configuration.instruction_class))
    end

    ## (PUT/PATCH/GET) - individual instruction
    def instruction_path(instruction)
    	## so it basically needs the whole product instruction combined path. 
    	main_app.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.instruction_class),instruction)
    end

	
	##/instructions (GET - all instructions /CREATE - individual instruction) 
	def instructions_path
    	main_app.send("shopping_product_instructions_path")
    end

    ##/shopping/instructions/:id/edit
    def edit_instruction_path(instruction)
    	main_app.send(Auth::OmniAuth::Path.edit_path(Auth.configuration.instruction_class),instruction)
    end
=end
end