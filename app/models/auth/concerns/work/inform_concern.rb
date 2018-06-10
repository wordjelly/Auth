module Auth::Concerns::Work::InformConcern

	extend ActiveSupport::Concern
	
	included do 	
		## what does this do really ?
		field :who_and_when_to_inform, type: Hash
		field :inform_on_actions, type: Array, default: []
			
		after_update do |document|
			document.inform if document.inform_on_actions.include? "after_update"
		end

		before_destroy do |document|
			document.inform if document.inform_on_actions.include? "before_destroy"
		end

		def inform
			self.who_and_when_to_inform.keys.each do |person_id|
				information = Auth::Work::Information.new
				information.resource_id = person_id
				information.send_at = self.who_and_when_to_inform[person_id]
				## other options can be added.
				## like payload and format.
				information.inform
			end
		end

	end

end