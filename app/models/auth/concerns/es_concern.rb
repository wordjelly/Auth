module Auth::Concerns::EsConcern

	extend ActiveSupport::Concern
	
	included do 

		def self.create_es_index(definition)
			definition ||= {}
			if Auth.configuration.use_es == true
				include Mongoid::Elasticsearch
				elasticsearch! (
						definition
					)
			end
		end	

	end



end