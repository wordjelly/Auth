require 'rails_helper'
RSpec.describe Auth::Workflow::Step, type: :model, :step_model => true do

	before(:all) do 

	end

	context " -- resolve time specs -- " do

		context " -- start_time_specifications present -- " do 

			it " -- raises error if minimum time since previous step missing -- " do 

				s = Auth.configuration.step_class.constantize.new
				s.applicable = true
				s.duration = 300
				s.time_information = {}
				s.time_information[:start_time_specification] = []
				expect {s.resolve_time(nil)}.to raise_error("minimum time since previous step is absent")	

			end

			context " -- previous step time information is provided -- " do 

				it " -- start time specification is not fulfilled, so throws an error -- " do 
					## 0 -> sunday, 1 -> monday, 2 -> tuesday, 3 -> wednesday, 4 -> thursday
					## lets give a start time specification which says thursday of any month in 2012.
					## and lets have an end time of the previous step so that it comes on a wednesday.
					s = Auth.configuration.step_class.constantize.new
					s.applicable = true
					s.duration = 300
					s.time_information = {}
					## basically any thursday of any year or month, from 12 am to 11.58:20 pm.
					s.time_information[:start_time_specification] = [["*","*","4","0","86300"]]
					s.time_information[:minimum_time_since_previous_step] = 0

					## now let us say the previous step time information
					## we want it to end on a friday.
					## so that it wont be accepted here.

					previous_step_time_information = {:start_time_range => [Time.new(2018,04,04).to_i, Time.new(2018,04,05).to_i], :end_time_range => [Time.new(2018,04,12,02,02).to_i, Time.new(2018,04,13,02,02).to_i]}


					expect {s.resolve_time(previous_step_time_information)}.to raise_error("does not satisfy the start time specification")


				end


				it " -- start time specification is fulfilled, so start time becomes end time of previous step + minimum time since previous step, and end time becomes start_time + duration -- " do 

					
					s = Auth.configuration.step_class.constantize.new

					s.applicable = true

					s.duration = 300

					s.time_information = {}
					
					s.time_information[:start_time_specification] = [["*","*","4","0","86300"]]

					s.time_information[:minimum_time_since_previous_step] = 0

					previous_step_time_information = {:start_time_range => [Time.new(2018,04,04).to_i, Time.new(2018,04,05).to_i], :end_time_range => [Time.new(2018,04,12,02,02).to_i, Time.new(2018,04,12,05,02).to_i]}

					s.resolve_time(previous_step_time_information)

					
					expect(s.time_information[:start_time_range]).to eq(previous_step_time_information[:end_time_range])

					expect(s.time_information[:end_time_range]).to eq(previous_step_time_information[:end_time_range].map{|c| c = c + s.duration})


				end


			end


			context " -- previous step time information is not provided -- " do 

				it " -- assigns the variables to the specification from the present time -- " do 

					s = Auth.configuration.step_class.constantize.new

					s.applicable = true

					s.duration = 300

					s.time_information = {}
					
					s.time_information[:start_time_specification] = [["*","*","4","0","86300"]]

					s.time_information[:minimum_time_since_previous_step] = 0

					s.resolve_time(nil)


					time_instance_to_consider = Time.now
					ymd = []
					ymd[0] = time_instance_to_consider.strftime("%Y")
					ymd[1] = time_instance_to_consider.strftime("%-m")
					ymd[2] = time_instance_to_consider.strftime("%w")

					beginning_of_day = DateTime.strptime(ymd.join(" "), '%Y %m %w')

					expect(s.time_information[:start_time_range]).to eq([beginning_of_day.to_i,beginning_of_day.to_i + 86300])


				end

			end

		end

		context " -- start_time specifications absent - " do

			context " -- previous step time specifications present -- " do 

				it " -- sets the start time range equal to the previous step end time range + the minimum time since the previou step -- " do 

					## so here we create a step
					## we give it some time information
					## and do from there.
					s = Auth.configuration.step_class.constantize.new
					s.applicable = true
					s.duration = 300
					previous_step_time_information = {:start_time_range => [Time.now - 5.days, Time.now - 4.days], :end_time_range => [Time.now - 3.days, Time.now - 4.days]}

					s.resolve_time(previous_step_time_information)
					## it should set the start_time + minimum time since previous step ?
					expect(s.time_information[:start_time_range]).to eq(previous_step_time_information[:end_time_range])

					expect(s.time_information[:end_time_range]).to eq(s.time_information[:start_time_range].map{|c| c = c + s.duration})

				end

			
			end

			context " -- previous step time specifications absent -- " do

				it " -- throws an error -- " do 

					s = Auth.configuration.step_class.constantize.new
					s.applicable = true
					s.duration = 300
					expect {s.resolve_time(nil)}.to raise_error("previous step time information absent")

				end

			end

		end


	end

	

end