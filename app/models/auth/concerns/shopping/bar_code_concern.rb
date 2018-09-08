module Auth::Concerns::Shopping::BarCodeConcern

	extend ActiveSupport::Concern

	included do 	
		attr_accessor :bar_code_tag
		attr_accessor :remove_bar_code

		after_find do |document| 
			## look for a barcode
=begin
			unless document.bar_code_tag
				bar_codes = Auth::Shopping::BarCode.where(:assigned_to_object_id => document.id.to_s, :assigned_to_object_class => document.class.name)
				if bar_codes.size == 1
					document.bar_code_tag = bar_codes.first.bar_code_tag
				end
			end
=end
		end

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
			if document.remove_bar_code == "1"
				if Auth::Shopping::BarCode.clear_object(document.id.to_s) == false
					document.errors.add(:bar_code_tag,"could not clear the barcode tag. Please try again later")
				end
			end
		end

		## do this after_save, so that at the minimum this bar_code_tag cannot be used again in this collection.
		## this has to be done before_save ?
		## if we do it before_save ?
		after_save do |document|
			
			unless document.bar_code_tag.nil?
				
				if bar_code_object = Auth::Shopping::BarCode.upsert_and_assign_object(self)

				else
					document.errors.add(:bar_code_tag,"the bar code tag could not be persisted")
				end

			end
		end
	end

end