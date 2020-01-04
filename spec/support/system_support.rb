module SystemSupport


	def lr(id,incoming_type="human")
		
		corr = {
			"first_location" => "5b04851f421aa910c46a01a2",
			"second_location" => "5b048531421aa910c46a01a3"
		}

		rev_corr = corr.values.zip(corr.keys)

		if incoming_type == "human"
			corr[id]
		else
			rev_corr[id]
		end

	end

	def create_from_file(file_path)

		description = JSON.parse(IO.read(file_path))
		cart_items = []
		products = []
		locations = []

		if description["locations"]
			description["locations"].each do |loc|
				location = Auth.configuration.location_class.constantize.new(loc)	
				expect(location.save).to be_truthy
				locations << location
			end
		end

		description["products"].each do |product|
			pro = Auth.configuration.product_class.constantize.new(product)
			pro.signed_in_resource = @admin
			pro.resource_id = @admin.id.to_s
			pro.resource_class = @admin.class.name.to_s
			expect(pro.save).to be_truthy
			products << pro
		end

		description["cart_items"].each do |citem|
			cart_item = Auth.configuration.cart_item_class.constantize.new(citem)
			## cart item shoudl inherit the bunch from the product.
			cart_item.resource_id = @u.id.to_s
			cart_item.resource_class = @u.class.name.to_s
			cart_item.signed_in_resource = @u
			expect(cart_item.save).to be_truthy
			cart_items << cart_item
		end

		wrapper = Auth::System::Wrapper.new(description["wrapper"])
		expect(wrapper.save).to be_truthy
		{:wrapper => wrapper, :cart_items => cart_items, :products => products, :locations => locations}
	end


	def get_transport_location_result(location_info_array,location_json_file_name="location_with_transport_information.json")

		json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/#{location_json_file_name}"))

		location_hashes = json_defintion["locations"]
		
		locations = location_hashes.map{|c|
			c = Auth.configuration.location_class.constantize.new(c)
			expect(c.save).to be_truthy
			c
		}


		response = Auth.configuration.location_class.constantize.find_entities_transport(location_info_array)
					
	end

	## will simply load consumable objects from the provided file
	def load_consumables(path)
		json_defintion = JSON.parse(IO.read(path))
		consumables = json_defintion["consumables"].map{|c|
			c = Auth::Workflow::Consumable.new(c)
		}	
		consumables
	end	

	def load_overlap_hash(path)
		overlap_hash = JSON.parse(IO.read(path))
		overlap_hash
	end

end

RSpec.configure do |config|
	config.include SystemSupport, :type => :request
	config.include SystemSupport, :type => :model
end