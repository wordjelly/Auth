class Auth::Workflow::Specification
	include Auth::Concerns::WorkflowConcern
	embedded_in :products, :class_name => Auth.configuration.product_class

	field :address, type: String
	## the problem is that while creating the cart_item, we will have to copy over the specifications as well.
	## so need to add a before_create callback in the cart_item

	## this is an array of specification arrays.
	## like : [[yy,mm,dd,number of seconds since midnight,number of seconds since midnight + some seconds],[...],[]]
	## the user can pick one of them.
	## each element has the following elements:
	## 0 -> year specification
	## 1 -> month specification
	## 2 -> day_of_month (1-31 : representing the dates)
	## 3 -> day_of_week (0->6 : representing monday -> sunday)
	## 4 -> seconds since midnight, minimum time after midnight at which this step can be started to be performed.
	## 5 -> how many seconds to add to the [4] to get the maximum time after midnight at which the step can be started. This can be any value, implying that the step can be started on some subsequent day , relative to this day.
	## these time specifications are added directly to the step that they refer to.
	## so we call get nearest instant here itself.
	field :permitted_start_time_ranges, type: Array
	
	## the index of the chosen specification from amongst the permitted_start_time_ranges
	## and actual will be got based on that.
	field :selected_start_time_range, type: Array

	## what location categories are permitted.
	field :permitted_location_categories, type: Array, default: []

	## which one is selected by the user.
	## should validate this as being one of the permitted location categories.
	field :selected_location_categories, type: Array

	## usually this is the location of the user
	## it is a hash of type: {:lat => ,:lng => }
	field :origin_location, type: Hash

	## has two elements, each can be a maximum and minimum within radius.
	field :permitted_within_radius, type: Array

	## has to lie in between the maximum and minimum limits.
	field :selected_within_radius, type: Float

	field :selected_location_ids, type: Array

	field :permitted_location_ids, type: Array, default: []

	validate :permitted_start_time_ranges_format
	
	## this has to be resolved from amongst all the options in the specification.
	## it has an order of preference like  :
	## if location ids are selected, then return those
	## if within radius is specified, then alongwith it origin_location should also be specified, and if location_categories are specified, then they should also be added to the hash.
	def location
		return {:location_ids => selected_location_ids} unless selected_location_ids.blank?
			
		if self.selected_within_radius 
			raise "origin location not provided" unless self.origin_location

			## if the selected location categories are not defined, make them equal to the permitted location categories.
			self.selected_location_categories ||= self.permitted_location_categories

			return {:within_radius => self.selected_within_radius, :origin_location => self.origin_location, :location_categories => self.selected_location_categories}
		end

		return nil
	end

	
	def start_time_range(current_time)

		return nil if permitted_start_time_ranges.blank?

		raise "start time range not selected" unless selected_start_time_range
	
		regex_pattern = ""
      		
		#puts "selected start time range is:" 
		#puts selected_start_time_range.to_s

      	selected_start_time_range[0..3].map.each_with_index{|value,key|
          if value =~ /\*/
            regex_pattern += "[0-9]{4}" if key == 0
            regex_pattern += "[0-9]{2}" if key == 1
            regex_pattern += "[0-9]{2}" if key == 2
            regex_pattern += "[0-9]{1}" if key == 3
          else
            regex_pattern += value
          end
      	}
        	
        #puts "the regex pattern is: #{regex_pattern}"

      	from_index = $day_id_hash[current_time.strftime($time_hash_strftime_format)]
      
      
      	nearest_day_midnight_epoch = nil
      
	    $date_hash.keys[from_index..-1].each_with_index {|dt,key|
	        nearest_day_midnight_epoch = (key*86400 + current_time.beginning_of_day.to_i) if dt=~/#{regex_pattern}/
	        if nearest_day_midnight_epoch
	        	#puts "dt is: #{dt}"
	    		#puts nearest_day_midnight_epoch.to_s
	    		break
	    	end
	    }

	    ## this is the nearest date

	    raise "matching date could not be found with specification" unless nearest_day_midnight_epoch

	    
	    {:start_time_range_beginning => nearest_day_midnight_epoch + selected_start_time_range[4].to_i, :start_time_range_end => nearest_day_midnight_epoch + selected_start_time_range[4].to_i + selected_start_time_range[5].to_i}

	end

	private

	
	def permitted_start_time_ranges_format
		
		permitted_start_time_ranges.each do |arr|
			arr.each_with_index{|val,key|
				unless val == "*"
					if key == 0
						## check that it is a valid year.
						self.errors.add(:permitted_start_time_ranges,"the year #{val}, is invald") unless val =~ /20\d\d/
					elsif key == 1
						## check that it is a valid month with two digits.
						self.errors.add(:permitted_start_time_ranges,"the month #{val}, is invald") unless val =~ /^(([0][1-9])|([1][0-2]))$/
					elsif key == 2
						## check that it is a valid day of month, zero padded left.
						self.errors.add(:permitted_start_time_ranges,"the day #{val}, is invald") unless val =~ /^(([0][1-9])|([1][0-9])|([2][0-9])|([3][0-2]))$/
					elsif key == 3
						## check that it is a single digit between 0-6
						self.errors.add(:permitted_start_time_ranges,"the day of week #{val}, is invald") unless val =~ /^(([0][1-9])|([1][0-9])|([2][0-9])|([3][0-2]))$/
					elsif key == 4
						## currently dont generate any errors here.
					elsif key == 5
					end
				end
			}
		end



	end



end