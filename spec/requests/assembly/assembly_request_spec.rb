require "rails_helper"

RSpec.describe "assembly request spec",:assembly => true, :type => :request do 


	before(:all) do 

	end

	context " -- json requests -- " do 

		context " -- permitted_params -- " do 

			it " -- permits step -- " do 
				
			end

			it " -- permits sop -- " do 

			end

			it " -- permits add_stage_ids -- " do 

			end

			it " -- permits remove_stage_ids -- " do 

			end
 
		end


		context " -- permissions -- " do 

			it " -- only admin can CRUD assemblies -- " do 



			end

		end

		context " -- create -- " do 

			context " -- assembly -- " do 

				it " -- checks if another assembly exists before creating -- " do 

				end

			end

			context " -- sop -- " do 

				it " -- where do all the controller requests go?" do 

				end

				it " -- cannot create sop if more than 1 or 0 assemblies are present -- " do 


				end

				it " -- validates presence of product in database "  do 


				end


				it " -- if stage id not provided, adds sop to first stage that doesn't contain the product, starting from earlist stage -- " do 



				end

				it " -- if stage id is provided, adds sop to that stage id -- " do 

				end


				it " -- if stage id is not provided, and last stage has sop/ no stages exist, creates a new stage with the sop -- " do 


				end

				it " -- if last stage with sop has an exit code matching the input code of a preceeding sop, then throws error, requiring the stage id to be provided -- " do 


				end

				it " -- can force add a stage if requested --  " do 


				end

				it " -- atomically controls creation, by passing in existing sop ids that already contain the product -- " do 

				end

			end

		end

	end

end