module Auth::Concerns::CloneConcern

	extend ActiveSupport::Concern

	included do 

		  ## overrides mongoid default clone method
  		## modified so that embedded objects are also cloned
  		## @return [Mongoid::Document] with all embedded documents assigned new ids.
  		def clone
  			new_doc = super
  			new_doc
      end

	end

end