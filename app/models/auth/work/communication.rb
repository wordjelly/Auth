class Auth::Work::Communication
	include Auth::Concerns::ChiefModelConcern
	###################################################################
	##
	##
	## ACCESSORS FOR CYCLE AND PRODUCT IDS.
	##
	##
	###################################################################

	## since we already find the cart item, instruction, cycle or product at the beginning, will store these as attr accessors, not naming as instruction/cycle/cart_item/product because i don't want to interfere with mongoid, which ideally should be setting these , but is not.
	attr_accessor :_instruction
	attr_accessor :_instruction_index
	attr_accessor :_cart_item

	## the communications own index in the instruction, or whatever is its parent.
	attr_accessor :_index
	attr_accessor :_product
	attr_accessor :_cycle
	attr_accessor :_cycle_index

	
	###################################################################
	##
	##
	## RELATIONS.
	##
	##
	###################################################################
	
	## now give the view to show this 
	embedded_in :cycle, :class_name => "Auth::Work::Cycle", :polymorphic => true

	## add embedded in products.
	embedded_in :instruction, :class_name => "Auth::Work::Instruction", :polymorphic => true

	###################################################################
	##
	##
	## METHODS FOR DEFER JOB.
	##
	##
	###################################################################

	field :method_to_determine_defer_job, type: String

	###################################################################
	##
	##
	## BASIC DESCRIPTION
	##
	##
	###################################################################
	field :name, type: String

	field :description, type: String
	###################################################################
	##
	##
	## EMAIL 
	##
	##
	###################################################################

	field :send_email, type: String

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
	## so this consists of what exactly ?
	## the hash is checked for the existence of two keys.
	## 
	## how to configure notification repeats ?
	## for eg someone books a 3 times a year diabetes plan.
	## when should the notifications be set ?
	## how to configure that ?
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
	field :repeat_times, type: Integer, default: 1

	## this is called to determine when to send this communication.
	field :method_to_determine_communication_timing, type: String

	## enqueue_at_time
	## this is not a permitted parameters.
	field :enqueue_at_time, type: Time

	## how many times was this notification repeated till now?
	field :repeated_times, type: Integer, default: 0

	def set_recipients
		self.recipients = {:users => [],:topics => []}
		if self.method_to_determine_recipients.nil?
			puts "no method to determine recipients."
			if self._instruction 
				if self._cart_item
					resource_id = self._cart_item.resource_id
					resource_class = self._cart_item.resource_class
					self.recipients[:users] << resource_class.constantize.find(resource_id)
				elsif self.product_id
					resource_id = self._product.resource_id
					resource_class = self._product.resource_class
					self.recipients[:users] << resource_class.constantize.find(resource_id)
				end
			else
				puts "no instruction found."
			end		
		else
			self.recipients = self.send("#{self.method_to_determine_recipients}",self.id.to_s)
		end
	end

	def set_enqueue_at
		if self.method_to_determine_communication_timing.nil?
			self.enqueue_at_time = Time.now 
		else
			self.enqueue_at_time = self.send("#{self.method_to_determine_communication_timing}",self.id.to_s)
		end
		self.enqueue_at_time
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

	def decrement_repeated_times
		
		if self._product
			Auth.configuration.product_class.constantize.where({
			"instructions.#{self._instruction_index}.communications.#{self._index}._id" => BSON::ObjectId(self.id.to_s) 
			}).find_one_and_update(
				{
					"$inc" => {
						"instructions.#{self._instruction_index}.communications.#{self._index}.repeated_times" => 1
					}
				},
				{
					:return_document => :after
				}
			)
		elsif self._cart_item
			Auth.configuration.cart_item_class.constantize.where({
					"instructions.#{self._instruction_index}.communications.#{self._index}._id" => BSON::ObjectId(self.id.to_s) 
				}).find_one_and_update(
				{
					"$inc" => {
						"instructions.#{self._instruction_index}.communications.#{self._index}.repeated_times" => 1
					}
				},
				{
					:return_document => :after
				}
			)
		elsif self._cycle
			#coll = Auth.configuration.cycle_class.constantize.collection
		end
		
	end

	def enqueue_repeat
		if self.repeated_times  < self.repeat_times
			if self.repeat
				if self.decrement_repeated_times
					puts "repeated times"
					puts self.repeated_times
					puts "repeat times."
					puts self.repeat_times
				
				
					
					enqueue_repeat_at = nil
					
					case self.repeat
					when "Daily"
						enqueue_repeat_at = Time.now + 1.day
					when "Weekly"
						enqueue_repeat_at = Time.now + 1.week
					when "Monthly"
						enqueue_repeat_at = Time.now + 1.month
					when "Yearly"
						enqueue_repeat_at = Time.now + 1.year
					when "Half-Monthly"
						enqueue_repeat_at = Time.now + 6.months
					end

					args = {}
					args[:instruction_id] = self._instruction.id.to_s if self._instruction
					args[:communication_id] = self.id.to_s
					args[:cart_item_id] = self._cart_item.id.to_s  if self._cart_item
					args[:product_id] = self._product.id.to_s  if self._product
					args[:cycle_id] = self._cycle.id.to_s  if self._cycle

					CommunicationJob.set(wait_until: enqueue_repeat_at).perform_later(args)
				end
			end
		end
	end


	## @return[Boolean] : will return false if there is no method defined which can help to determine if the job should be done or deferred. Will otherwise call that method, and return its result.
	## that method is expected to return a Time object that will be used by the communicationJob to requeue itself.
	def defer_job
	 	return false if self.method_to_determine_defer_job.nil?
	 	self.send("#{self.method_to_determine_defer_job}",self.id.to_s)
	end

	## @return[Time] : returns a time object at which this job should be reenqueud. If it does not return a time object, then the job is not to be reenqueud, and basically was done immediately.
	def deliver_all
		defer_job_result = defer_job
		unless defer_job_result == false
					return defer_job_result
		end
		set_recipients
		deliver_email
		deliver_sms
		deliver_mobile_notification
		enqueue_repeat
		return nil
	end	

	def get_parent_object
		self._instruction || self._cycle
	end

	def deliver_email
		return unless self.send_email == "on"
		self.recipients[:users].each do |recipient|
			puts "checking email recipient."
			puts recipient.email.to_s
			puts recipient.confirmed_at.to_s
			if recipient.email && recipient.confirmed_at
				puts "sending email."
				Auth::SendMail.send_email({to: recipient.email, subject: get_parent_object.get_email_subject, content: get_parent_object.get_email_content, link: get_parent_object.get_link}).deliver
			end
		end
	end

	def deliver_sms	
		self.recipients[:users].each do |recipient|
			if recipient.additional_login_param
				###################################################
				## SET NUMBER
				###################################################
				to_number = recipient.additional_login_param
					
				###################################################
				## SET TEMPLATE NAME
				###################################################
				template_name = Auth.configuration.two_factor_otp_transactional_sms_template_name
				
				###################################################
				##
				##
				## SET VAR HASH
				##
				##
				###################################################
				var_hash = {:var2 => get_parent_object.get_link, :var1 => get_parent_object.get_sms_content}
				
				########################################################
				## SET TEMPLATE SENDER ID
				#######################################################	
				template_sender_id = Auth.configuration.two_factor_otp_transactional_sms_template_sender_id

				########################################################
				## ONLY SEND THE SMS IF THE VAR HASH CONTAINS DATA.
							
				url = "https://2factor.in/API/R1/?module=TRANS_SMS"
		
				params = {
					apikey: Auth.configuration.third_party_api_keys[:two_factor_sms_api_key],
					to: to_number,
					from: template_sender_id,
					templatename: template_name,
				}.merge(var_hash)
				
				request = Typhoeus::Request.new(
				  url,
				  params: params,
				  timeout: 10
				)

				response = request.run
					
			end
		end
	end




	def deliver_mobile_notification

	end



	#####################################################################
	##
	##
	## CLASS METHODS.
	##
	##
	#####################################################################
	def self.find_communication(arguments)
		communication_id = arguments[:communication_id]
	    instruction_id = arguments[:instruction_id]
	    cart_item_id = arguments[:cart_item_id]
	    if communication_id && instruction_id && cart_item_id
	      	if cart_item = Auth.configuration.cart_item_class.constantize.find(cart_item_id)
		        instruction = nil
		        instruction_index = nil
		        communication = nil
		        communication_index = nil

		        cart_item.instructions.each_with_index{|value,key|
		        	if value.id.to_s == instruction_id
		        		instruction = value
		        		instruction_index = key
		        	end
		        }

		        instruction.communications.each_with_index{|value,key|

		        	if value.id.to_s == communication_id
		        		communication = value
		        		communication_index = key
		        	end

		        }

		        instruction.cart_item_id = cart_item_id
		        communication._instruction = instruction
		        communication._cart_item = cart_item
		        communication._instruction_index = instruction_index
		        communication._index = communication_index

		        return communication
	      	end
	    elsif communication_id && instruction_id && product_id

	    end	
	end


end
