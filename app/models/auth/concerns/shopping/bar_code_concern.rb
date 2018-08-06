module Auth::Concerns::Shopping::BarCodeConcern

	extend ActiveSupport::Concern

	included do 	
		field :bar_code_tag, type: String
		attr_accessor :remove_bar_code

		## do this before validation so that it provides a way to prevent the document from being saved, in case the bar code collection cannot be updated successfully.
		before_validation do |document|
			if document.bar_code_tag_changed? && document.bar_code_tag.nil?
				
				
				
			end
		end

		## do this after_save, so that at the minimum this bar_code_tag cannot be used again in this collection.
		after_save do |document|
			if document.bar_code_tag_changed? && document.bar_code_tag_was.nil?
				


			end
		end
	end
end

## how will all this finish.?