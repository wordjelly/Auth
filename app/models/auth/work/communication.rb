class Auth::Work::Communication
	include Auth::Concerns::ChiefModelConcern
		
	## 1. it has been embedded, now let me create the ui to edit the communication, for email fields, and then we proceed to email, for this we will need routes and forms.
	## so i need to see how the communications were made.
	## 2. finish the surveys
	## 3. finish two tradegenie tests
	## 4. finish booking cycle.


	###################################################################
	##
	##
	## ACCESSORS FOR CYCLE AND PRODUCT IDS.
	##
	##
	###################################################################

	attr_accessor :cycle_id
	attr_accessor :instruction_id

	###################################################################
	##
	##
	## RELATIONS.
	##
	##
	###################################################################
	
	## now give the view to show this 
	embedded_in :cycles, :class_name => "Auth::Work::Cycle", :polymorphic => true

	## add embedded in products.
	embedded_in :instructions, :class_name => "Auth::Work::Instruction", :polymorphic => true

	###################################################################
	##
	##
	## EMAIL 
	##
	##
	###################################################################

	field :send_email, type: Boolean

	field :email_template_path, type: String

	###################################################################
	##
	##
	## RECIPIENT DETERMINATION.
	##
	##
	###################################################################

	## this method is called on self.
	## and the self id is passed as an argument.
	## eg : self.send("instruction.cart_item.get_recipients",self.id.to_s)
	field :method_to_determine_recipients, type: String

	## this is got by calling the above method.
	## this is not a permitted parameter.
	field :recipients, type: Hash

	###################################################################
	##
	## 
	## communication REPEATS
	##
	##
	###################################################################

	## "daily,weekly,monthly,yearly"
	field :repeat, type: String

	## how many times to repeat it.
	field :repeat_times, type: Integer

	## this is called to determine when to send this communication.
	field :method_to_determine_communication_timing, type: String

	## enqueue_at_time
	## this is not a permitted parameters.
	field :enqueue_at_time, type: Time

	def set_recipients
		self.recipients = self.send("#{self.method_to_determine_recipients}",self.id.to_s)
	end

	def set_enqueue_at_time
		self.enqueue_at_time = self.send("#{self.method_to_determine_communication_timing}",self.id.to_s)
	end

	def repeat_options
		[
			["Daily","Daily"],
			["Weekly","Weekly"],
			["Monthly","Monthly"],
			["Yearly","Yearly"],
			["Half-Monthly","Half-Monthly"],
			["Saturday","Saturday"],
			["Sunday","Sunday"],
			["Monday","Monday"],
			["Tuesday","Tuesday"],
			["Wednesday","Wednesday"]
		]
	end

end