module Auth::Concerns::ChiefModelConcern

	extend ActiveSupport::Concern

	included do 


		

		include Mongoid::Document
		include Mongoid::Timestamps
		include Mongoid::EmbeddedErrors
		include Auth::Concerns::ImageLoadConcern
		## expected to be a hash with names of callbacks and boolean values.
		## eg: {:before_save => true, :after_save => false..}
		## used in conjunction with the provided skip_callback?(callback_name) method to determine whether to execute the callbacks or not.
		## so basically before saving the document, set this attr_accessor on it, and it will allow you to control if callbacks are executed or not.
		## currently used in the after_save callback where we dont want the refund being set to accepted, and thereafter to update all other refunds as failed to cascade.
		attr_accessor :skip_callbacks

		## these are for adding embedded documents.
		attr_accessor :embedded_document_path

		## any embedded document to be changed is to be added here.
		attr_accessor :embedded_document

		## array of image ids, that are associated with the current document.
		
		## moved field public to the es_concern.

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


		## @param[Parameters] params : the params passed into the controller where this model was initialzied
		## @param[Hash] permitted_params : the permitted_parameters for the controller
		## @param[ActiveObject] : the model instance.
		## @return[Boolean] : the result of saving the model.
		def create_with_conditions(params,permitted_params,model)
			model.save(permitted_params)
	  	end


	  	## @param[Parameters] params : the params passed into the controller where this model was initialzied
		## @param[Hash] permitted_params : the permitted_parameters for the model,for eg : if the model is :assembly, then the permitted params will e everything under the :assembly key in the incoming parameters.
		## @param[ActiveObject] : the model instance.
		## @return[Boolean] : the result of saving the model.
  		def update_with_conditions(params,permitted_params,model)
    		model.save
  		end


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

  		## or will have to define a get_parent function.
  		## which will all be very complicated.
  		## if a stage is made not_applicable -> then all the children become applicable, 
  		## if it is again made applicable -> all the children go back to what?
  		
  		
  		## so you can delete a step forever only if it is not applicable.
  		## so to mark a parent as inapplicable, find where, 
  		## any of them is not 
  		## so mark applicable -> can you mark something as applicable
  		## you cannot mark a parent as inapplicable = if any of its children are inapplicable, first delete them.
  		## now suppose you mark something as 
  		## okay so that works.
  		## suppose you mark somthing as applicable -> only possible if all the children are 


  		## remember that when you mark something as applicable -> it will not make any of the children applicable.
  		## you cannot mark something as applicable if any of the children are inapplicable
  		## 

  		

  		## override in your model. Is called by the #index action of the authenticated_controller.
  		## all the search criteria should be set on the model instance passed into the index action.
  		## @return[Array] array of self objects.
  		def get_many
  			[]
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