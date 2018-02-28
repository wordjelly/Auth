module Auth::Concerns::ChiefModelConcern

	extend ActiveSupport::Concern

	included do 


		

		include Mongoid::Document
		include Mongoid::Timestamps

		## expected to be a hash with names of callbacks and boolean values.
		## eg: {:before_save => true, :after_save => false..}
		## used in conjunction with the provided skip_callback?(callback_name) method to determine whether to execute the callbacks or not.
		## so basically before saving the document, set this attr_accessor on it, and it will allow you to control if callbacks are executed or not.
		## currently used in the after_save callback where we dont want the refund being set to accepted, and thereafter to update all other refunds as failed to cascade.
		attr_accessor :skip_callbacks


		field :public, type:String, default: "no"


		def field_names_to_skip_while_making_form
			["_id","_type.,","resource_id","resource_class","created_at","updated_at","public"]
		end

		def publicly_visible_field_names 
			[]
		end


		## returns a list of attributes of tis model other than those mentioned in #FIELD_NAMES_TO_SKIP_WHILE_MAKING_FORM in this concern.
		## this is only used in the web api.
		## @return[Array] array_of_strings : field name.
		def attributes_to_show
			self.class.attribute_names.keep_if{|c| !self.field_names_to_skip_while_making_form.include? c.to_s}
		end

		## @return[Array]
		def public_attributes_to_show
			self.publicly_visible_field_names
		end


		def text_representation
			self.attributes.to_s
		end

	end

	## @param callback_name[String] : the name of the callback which you want to know if is to be skipped
	## return[Boolean] : true or false.
	## checks whether the attr_accessor skip_callbacks is set, and if yes, then whether the name of this callback exists in it.
	## if both above are no, then returns false
	## if the name exists, then return whatever is stored for the name i.e true or false.
	## @used_in the after_save and before_save callback blocks, as the first line, basically only executes the block if this method returns false.
	def skip_callback?(callback_name)
		return false if (self.skip_callbacks.blank? || self.skip_callbacks[callback_name.to_sym].nil?)
		return self.skip_callbacks[callback_name.to_sym] == true
	end

	## will iterate the superclasses of this class
	## until it finds a class that begins with Auth::
	## or it hits Object
	## and then it returns that superclass whatever it is.
	def walk_superclasses
		my_super_class = self.class.superclass
		while my_super_class != Object
			break if my_super_class.to_s =~ /^Auth::/
			my_super_class = my_super_class.superclass 
		end
		return my_super_class
	end

	

end