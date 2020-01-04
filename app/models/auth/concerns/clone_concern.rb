module Auth::Concerns::CloneConcern

	extend ActiveSupport::Concern

	included do 
		  ## overrides mongoid default clone method
  		## modified so that embedded objects are also cloned
  		## @return [Mongoid::Document] with all embedded documents assigned new ids.
  		def clone
        #puts " --------- COMING TO CLONE OVERRIDE ------------"
  			new_doc = super
=begin
        puts "Came past super."
        puts "self attributes are:"
        puts self.attributes
        new_doc.attributes.each do |attr|
          puts "doing attribute : #{attr}"
          attribute_name = attr[0]
          if attr.respond_to? :embedded_in
            puts "responds to embedded."
            mapped_docs = new_doc.send("#{attribute_name}").map {|k|
              puts "k older id is: #{k.id.to_s}"
              l = k.clone
              puts "k new id is: #{l.id.to_s}"
              l
            }
            new_doc.send("#{attribute_name}=",mapped_docs)
            #new_doc.send("#{attr}=",new_doc.send("#{attr}").map{|c| c = c.clone})
          end
        end
=end
  			new_doc
      end

	end

end