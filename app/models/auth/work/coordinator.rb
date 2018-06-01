class Auth::Work::Coordinator
	## this function creates the cycles, for all minutes between the start time and end time.
	## product ids if nil will do for all product ids.
	def create_cycles(start_time,end_time,location_id,product_id_array=["*"])

		## inside the worker schdule we have to get write location, time start and end
		## and we also have entity schedule
		## so those will be seperate or also products only ?
		## 
		## then we have to assemble for each minute, with all the available workers, and machines for each and every location
		## and then start adding the cycles that can be done at those minutes
		## now this whole thing is doable
		## the subsequent part is harder
		## maybe i try that first.
		## in that we have to get which workers are applicable to the cycle and then proceed
		## then there is the overlapping bookings
		## and the incoming traveller search.
		## and the cycle 
		## this will take 3 weeks.
		## to write test and workout to perfection.
		## minimum 3 hours per day
	end

	## make the schedules this will be for machines and workers both.
	## if the machine is going to be a product ?
	## or what
	## no we make a seperate machine model.
end
