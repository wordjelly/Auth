class Auth::Workflow::StagesController < Auth::Workflow::WorkflowController
  
  	## to create a stage
  	## pass in the assembly id
  	## and the assembly.doc_version
  	## where ->
  	## addtoset

	## to update a stage
	## pass in stage_id
	## pass in stage_doc_version
	## pass in stage_index
	## where -> {stages.index.id => id, stages.index.doc_version => whatever}
	## update -> whatever has to be updated.

	## tomorrow -> 1) finalize the create and update
	## do them all in the same controller, no seperate controllers
	## add tests for that
	## add image concern to all of them
	## finalize about additional_parameter_passing
	## finalize inner workings of exit_code, entry_code
	## how to do for repeat a particular section.
	## how to program for sample_requirements
	## how to interpret for sop_result, step_result.
	

end