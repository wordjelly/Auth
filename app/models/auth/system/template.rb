class Auth::System::Template
	
	embedded_in :crawl, :class_name => "Auth::System::Crawl"
	field :product_id_to_generate, type: String
	field :amount_generated, type: Float
	field :start_amount, type: Float, default: 0.0

	field :summate, type: Boolean
	field :summate_with_index, type: Integer
	field :create_new_item_if_amount_crosses, default: 1.0

	
	def add_item_to_output_hash(output_hash,template_index) 
		output_hash[product_id_to_generate] = [{:template_id => self.id.to_s, :from => self.start_amount, :to => self.amount_generated, :template_index => template_index, :original_template_id => self.id.to_s}]
		output_hash
	end

	def summate_items(output_hash,template_index)
		template_key = self.summate_with_index || template_index
		output_hash[product_id_to_generate] = []
		self.crawl.output_array.reverse.each_with_index {|prev_citem_output,key|
			prev_citem_output.each_key do |product_id|
				tmp = prev_citem_output[product_id]
				if tmp[:template_index] == template_key
					if (tmp[:to] + self.amount_generated) > self.create_new_item_if_amount_crosses
						add_item_to_output_hash(output_hash,template_index)
					else
						output_hash[product_id_to_generate] << {
							:template_id => tmp[:original_template_id], 
							:from => tmp[:to],
							:to => tmp[:to] + self.amount_generated,
							:template_index => template_index,
							:original_template_id => self.id.to_s
						}
					end
				end				
			end
		}
	end

	
end
