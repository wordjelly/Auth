module ActiveModel
  module Validations
    UrlValidator.class_eval do 
    	def validate_each(record, attribute, value)
    		url = nil
    		uri = nil
	        if value.is_a? Array
	        	value.each do |v|
	        		begin
			          url = ensure_protocol(v)
			          uri = Addressable::URI.parse(url)
			        rescue
			          invalid = true
			        end
	        	end
	        else
	        	begin
		          url = ensure_protocol(value[0])
		          uri = Addressable::URI.parse(url)
		        rescue
		          invalid = true
		        end	
	        end

	       
	     
	        unless !invalid && valid_scheme?(uri.scheme) && valid_host?(uri.host) && valid_path?(uri.path)
	          record.errors[attribute] << ( "#{value.to_s} contains invalid URLS")
	        end


	    end

    end
  end
end