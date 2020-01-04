module Auth::Concerns::Shopping::BarCodeConcern

	extend ActiveSupport::Concern

	included do 	
		attr_accessor :bar_code_tag
		attr_accessor :remove_bar_code

		after_find do |document| 
			## look for a barcode
			unless document.bar_code_tag
				bar_codes = Auth::Shopping::BarCode.where(:assigned_to_object_id => document.id.to_s, :assigned_to_object_class => document.class.name)
				if bar_codes.size == 1
					document.bar_code_tag = bar_codes.first.bar_code_tag
				end
			end
		end

		## so if i want to assign a barcode , i.e the same barcode to the unit.
		## how to do that?
		## scan the barcode(from step show) -> go to the product(with some arguments) -> click button called assign to unit -> it updates the unit with a barcode.
		## now when we scan the barcode -> it goes to barcode controller -> and there it searches for a class with that.

		before_validation do |document|
=begin
			## if the tag has changed, and if it was not nil
			if document.bar_code_tag_changed? && !document.bar_code_tag_was.nil?
				## it will relieve the original barcode from this object
				## that barcode will now no longer be assigned to anything, 
				## and this new barcode will be saved, as long as that clear operation was successfu
				if Auth::Shopping::BarCode.clear_object(document.id.to_s) == false
					document.errors.add(:bar_code_tag,"could not clear the barcode tag. Please try again later")
				end
			end
=end
			## will have to remove it from product.
			## then reassign it to unit.
			## that's the only way.
			## first update product -> remove_bar code.
			## then save the unit with it.
			## product update will have to be carried out internally.
			
			if document.remove_bar_code == "1"
				puts "remove bar code was 1"
				if Auth::Shopping::BarCode.clear_object(document.id.to_s) == false
					document.errors.add(:bar_code_tag,"could not clear the barcode tag. Please try again later")
				else
					puts "clear barcode succeeds."
					## remove the barcode from the object, that was loaded at find.
					document.bar_code_tag = nil
				end
			end
		end

		## do this after_save, so that at the minimum this bar_code_tag cannot be used again in this collection.
		## this has to be done before_save ?
		## if we do it before_save ?
		after_save do |document|
			
			puts "Came to after_Save product."
			
			unless document.bar_code_tag.blank?
				
				#puts "bar code tag is not nil"
				#puts "barcode tag is:"
				
				#puts "-----------|||||||||||||||||||||||||"
				#puts document.bar_code_tag.to_s
				#puts "-----------|||||||||||||||||||||||||"

				if bar_code_object = Auth::Shopping::BarCode.upsert_and_assign_object(self)
					#puts "upsert and assign works."
					#puts "self barcode is:"
					#puts self.bar_code_tag.to_s
				else
					document.errors.add(:bar_code_tag,"the bar code tag could not be persisted")
				end

			end

		end

	end

end