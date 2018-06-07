class Auth::Work::Cycle
		
	include Mongoid::Document

	## for aggs.
	attr_accessor :cycle_index

	field :origin_epoch

	embedded_in :minutes, :class_name => "Auth::Work::Minute", :polymorphic => true

	embedded_in :products, :class_name => Auth.configuration.product_class, :polymorphic => true

	embeds_many :templates, :class_name => "Auth::Work::Template"

	## each cycle will have a limit
	field :capacity, type: Integer, default: 0

	## there will have to be another field, saying workers who can do it, and entities who can do it.
	field :workers_available, type: Array


	## it will have a list of workers to whom it is assigned
	field :workers_assigned, type: Array

	
	## the available entities, these are set at the time of creating the minutes.
	field :entities_available, type: Array


	## the entities assigned, finally.
	field :entities_assigned, type: Array


	## it has to have a priority score
	field :priority, type: Float

	## it has a fixed duration.
	field :duration, type: Integer

	## time to next cycle
	field :time_since_prev_cycle, type: Integer, default: 0
	
	field :time_to_next_cycle, type: Integer

	## to process one product.
	## how does the multiple work?
	## how many to pass into the product crawl calculation, is it directly linear, or do we have a specific function?	
	field :output, type: Array, default: []

=begin
	cycle_type => quantity
	* cycle_type is a field registered on both 'user_concern' and 'auth/work/entity.rb'
=end
	field :requirements, type: Hash

	field :cycle_code, type: String

	## the ids of the related cycles.
	field :cycle_chain, type: Array

	before_save do |document|
		document.cycle_code = BSON::ObjectId.new.to_s unless document.cycle_code
	end


	## @param[Array] prev_step_output: array of output hashes
	## @param[Array] cart_item_ids: array of cart item ids to be processed.
	## @return[Array] output : array of output hashes. Uses the templates to generate these hashes.
	def generate_output(prev_step_output,cart_item_ids=nil)
		if cart_item_ids.nil?
			prev_step_output.each do |cart_item_output|

			end
		else
			cart_item_ids.each do |cid|
				output_hash = {}
				## each template is for one product id.
				## and inside summate it can crosses the individual products to do the summation.
				self.templates.each_with_index {|template,key|
					if template.summate
						template.summate_items(key,output_hash)
					else
						template.add_item_to_output_hash(key,output_hash) 
					end
				}
				self.output << output_hash
			end
		end
	end

	def requirements_satisfied(epoch,location_id)
		
		#puts "came to requirements satisfied"
		Auth.configuration.location_class.constantize.all.each do |l|
			puts l.attributes.to_s
		end
		location = Auth.configuration.location_class.constantize.find(location_id)
		
		#puts "location found :#{location}"
		#puts "epoch : #{epoch}, and location id: #{location_id}"
		time_for_query = Time.at(epoch)
		applicable_schedules = Auth::Work::Schedule.collection.find({
			"$and" => [
				{
					"location_id" => location_id
				},
				{
					"start_time" => {
						"$lte" => time_for_query
					}
				},
				{
					"end_time" => {
						"$gte" => time_for_query
					}
				}
			]
		})
		


		#puts "applicable schedules:"
		#puts applicable_schedules.to_s

		applicable_schedules = applicable_schedules.to_a

		return false if (applicable_schedules.blank? || applicable_schedules.size == 0)
		
		#puts "there are applicable schedules"

		req = self.requirements.deep_dup
		#puts "req are:"
		#puts req.to_s
		
		applicable_schedules.map!{|c| c = Mongoid::Factory.from_db(Auth::Work::Schedule,c)}

		## here basically suppose you have n applicable schedules.
		## you need to combine them into cycle categories and see how many combinations you get out of it.

		available_resources = {}

		applicable_schedules.each do |schedule|
			
			schedule_for_object = schedule.for_object_class.constantize.find(schedule.for_object_id)
			
			schedule_for_object.cycle_types.keys.each do |type|
				#req[type] = req[type] - 1 if req[type]
				available_resources[type] = 0 unless available_resources[type]
				available_resources[type]+=1
			end

		end
		
		## now we have certain type counts necessary for this cycle.
		## now how to return the available capacity.
		#k = req.values.uniq
		#return true if ((k[0] == 0) && (k.size == 1))
		#return false

		## so how to split into multiples ?
		## just do it sequentially.
		failed = false
		while failed == false
			self.requirements.keys.each do |req|
				failed = true unless available_resources[req]
				break unless available_resources[req]
				failed = true if available_resources[req] < self.requirements[req]
				break if available_resources[req] < self.requirements[req]
				available_resources[req] -= self.requirements[req]
			end
			self.capacity+=1 if failed == false
		end
	
		## now this becomes the cycle capacity.
		## but only for the origin minute.
		
		return self.capacity > 0

	end


	###########################################################
	##
	##
	## BOOKINGS.
	##
	##
	###########################################################

	

	def after_book
		Auth::Work::Minute.get_affected_minutes(self.start_time,self.end_time,self.workers_assigned,self.entities_assigned).each do |minute|
		
			## each cycle has its index as cycle_index
			## this is used to update the cycles.
		
		end
	end

	def book
		after_book
	end

	
	## so the search criteria is 
	## where entity_ids == [n1,n2,n3], or worker_ids= [y1,y2,y3]
	## range is such that
	## if (end time or start time) of any cycle is (from this minute -> time of end of this cycle)
	## or if start time <= this minute, and end time is  >= minute of end of this cycle.  
	## for any of those cycles -> if priority is applicable, then block, and block all related chains.
	## how to block the related chains ?
	## a cycle has to store all its related chain ids, and also its 30 minute references.
	## so that's it.
	## this is something to execute tomorrow.

	## so plan for today
	## 

end



	

	
	

	


	
	



=begin
ARCHITECTURE :

1.First embedded crawls inside products
2.Each product thus has an array of crawls. These are basically the individual sop's that have to be done for the product.

3.Inside each crawl embedded many templates.
4.Inside each crawl is also a field called "output" : this is an array. 5.Each element in this array stores the output generated by passing each of the prodcuts through the template array in the crawl.
6.The idea is that the template defines what is output from the crawl, if one single product is to be processed.

7.How does the templating work
8.Imagine, 3 products have to be processed.
So we start with an array of 3 products :
[c_item1,c_item2,c_item3]

Now we pass each item to the whole array of templates.
For each item we initialize a hash called an output hash.
Then we see if the template has summate on or off.

## => if summate is off : it adds an entry to the output_hash, with the key as the product_id_to_generate from the template, and the value as a hash.
## this contains the template_id itself, the from(this will be the same as the start_amount described below), the to(this will be the from + the amount_generated), the original_template_id : the same as the template_id, (in case of summate this is maintained, so that we can keep a track of the original id.)
## so now we add this to the output_hash, if the hash already contains the product_id, then we just append this hash to that key.

## => If summate is on, we call template.summate
this function will basically look in all the output hashes(it iterates #output mentionedin point 2 in reverse.).
For each template we have stored the following three attributes :
1. summate_index : the index of the template with which we have to try to summate this from the previous product output hashes.
2. summate : true /false
3. create_new_item_if_amount_crosses : the amount that if crossed,in a given products template, then we wont just summate, but instead we will create a new product.

SO how summate works is like this, 
if the template says summate, it looks in the output hash of the previous product.
there it first takes the product_to_be_generated key, and then in that it will look inside each template, if the template index matches, whatever has been defined in summate_indx, then it will try to summate with that. so there what it will do is take the from and to, and then take the amount to be added, if after adding to the to, it crosses the (3) defined above, we will then have to create a new template, othewise, we will use the template id of the template into which this was fused, and add that to the output hash. If you use the template id of a previous template(i.e from another product), then you have to set the original_template_id to whatever is the current template that you are making. That brings out another TODO: i.e the template ids will remain the same for each product passed, through, and these need to be changed.

Eg:
Product : {
	Crawls : [
		{
			templates : [
				{
					:product_id_to_generate => the id of the product that is to be generated, eg: red tube,
					:amount_generated => How much of this product is to be generated, eg 2ml,
					:start_amount => what does the product start with, eg: 0 ml,
					:summate => whether we should try to summate, for eg if a previous product ,
					:summate_with_index: ,
					:create_new_item_if_amount_crosses: ,
				}
			]		
		},
		{
	
		}
	]
}


=end
