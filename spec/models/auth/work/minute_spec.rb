require 'rails_helper'
RSpec.describe Auth::Shopping::Product, type: :model, :minute_model => true do

	context " -- wrapper -- " do 

		before(:example) do 
			clean_all_work_related_classes
		end

		it " -- finds the affected cycles -- " do 

			start_minute = Time.new(2012,05,05,10,10,0).to_i
			5.times do |n|
				minute = Auth::Work::Minute.new
				minute.time = start_minute
				2.times do |c|
					cycle = Auth::Work::Cycle.new
					cycle.start_time = minute.time.to_i
					cycle.duration = 10
					cycle.end_time = cycle.start_time + cycle.duration
					cycle.requirements = {
		            	:person_trained_on_em_200 => 1,
		            	:em_200 => 1
		            }
		            cycle.workers_available = ["first_worker","second_worker"]
		            cycle.entities_available = ["first_entity","second_entity"]
		            minute.cycles << cycle
				end
				minute.save
				start_minute = start_minute + 60.seconds
			end

			## now we have 5 minutes, each with 2 cycles.
			## now lets search for the affected cycles.
			## we will give a minute range that encomapsses the last three minutes.
			affected_minutes = Auth::Work::Minute.get_affected_minutes(Time.new(2012,05,05,10,13,0).to_i,Time.new(2012,05,05,10,16,0).to_i,["first_worker"],["second_entity"])

			## so first of all does it touch the correct cycels ?
			total_affected_cycles = 0
			affected_minutes.each do |minute|
				total_affected_cycles+= minute.cycles.size
			end
			expect(total_affected_cycles).to eq(4)

		end

		it " -- updates affected cycles part 1 -- " do 

			start_minute = Time.new(2012,05,05,10,10,0).to_i
			5.times do |n|
				minute = Auth::Work::Minute.new
				minute.time = start_minute
				2.times do |c|
					cycle = Auth::Work::Cycle.new
					cycle.start_time = minute.time.to_i
					cycle.duration = 10
					cycle.end_time = cycle.start_time + cycle.duration
					cycle.requirements = {
		            	:person_trained_on_em_200 => 1,
		            	:em_200 => 1
		            }
		            cycle.workers_available = ["first_worker","second_worker"]
		            cycle.entities_available = ["first_entity","second_entity"]
		            minute.cycles << cycle
				end
				minute.save
				start_minute = start_minute + 60.seconds
			end

			## now we have 5 minutes, each with 2 cycles.
			## now lets search for the affected cycles.
			## we will give a minute range that encomapsses the last three minutes.
			affected_minutes = Auth::Work::Minute.get_affected_minutes(Time.new(2012,05,05,10,13,0).to_i,Time.new(2012,05,05,10,16,0).to_i,["first_worker"],["second_entity"])


			updated_minutes = Auth::Work::Minute.update_affected_minutes(affected_minutes,["first_worker"],["second_entity"])


			updated_minutes.uniq!

			updated_minutes.each do |u_min|
				u_min.cycles.each do |cycle|
					puts cycle.attributes.to_s
				end
			end

			expect(updated_minutes.size).to eq(affected_minutes.size)
			## okay so what is the expectation here exactly
			## what should this method return ?

		end

		it " -- updates the cycle chains of all the affected cycles -- " do 

			## since we have grouped it by minute, we can update it in one shot directly since we have 
			## we basically have to pull and push from the assigned workers and assigned entities at that index.

		end

	end

end

## rough plan
## 10 -> 20 : finish the cycles, and then decide what kind of ui it should have, test object + integration with shopping cart + notifications + video / image integration with cycle + bar code.
## 20 -> 30 : b2b + collection boy interface + location interface + apis for the symptoms, videos, image + 
## 20 -> 30 : cycle ui + symptom test
## 1 -> 7 : add all the cycles and steps into the 
