module Auth::Concerns::CloneConcern

	extend ActiveSupport::Concern

	included do 

		## overrides mongoid default clone method
  		## modified so that embedded objects are also cloned
  		## @return [Mongoid::Document] with all embedded documents assigned new ids.
  		def clone
  			new_doc = super
  			self.attributes.keys.each do |attr|
  				if new_doc.send("#{attr}").respond_to? "__metadata"
  			  		new_doc.send("#{attr}=",new_doc.send("#{attr}").map{|c| c = c.clone 
  			  			c})
  				end
  			end
  			new_doc
  		end

	end

end