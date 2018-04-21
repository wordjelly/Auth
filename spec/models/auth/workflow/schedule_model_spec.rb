require 'rails_helper'
RSpec.describe Auth::Workflow::Schedule, type: :model, :schedule_model => true do

	context " -- wrapper -- " do 

		before(:all) do

		end

		context " -- load from json file -- " do 

			it " -- creates schedules -- " do 
				response = load_and_create_schedules_bookings_and_requirements("/home/bhargav/Github/auth/spec/test_json_assemblies/two_schedules_two_requirements_two_bookings_two_slots.json")
				## does this save the schedules ?
				schedules = response[:schedules]
				expect(schedules.size).to eq(2)
				schedules.map{|s|
					expect(s.save).to be_truthy
				}
			end

			it " -- creates requirements specified in schedule -- " do 
				expect(Auth.configuration.requirement_class.constantize.all.size).to eq(0)
				response = load_and_create_schedules_bookings_and_requirements("/home/bhargav/Github/auth/spec/test_json_assemblies/two_schedules_two_requirements_two_bookings_two_slots.json")
				## does this save the schedules ?
				schedules = response[:schedules]
				expect(schedules.size).to eq(2)
				schedules.map{|s|
					expect(s.save).to be_truthy
				}
				expect(Auth.configuration.requirement_class.constantize.all.size).to eq(2)
			end

		end



	end

end