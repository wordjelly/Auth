module SystemSupport

	## @return[Auth::System::Wrapper]

	def create_from_file(file_path)

		description = JSON.parse(IO.read(file_path))

		description["products"].each do |product|
			pro = Auth.configuration.product_class.constantize.new(product)
			pro.signed_in_resource = @admin
			pro.resource_id = @admin.id.to_s
			pro.resource_class = @admin.class.name.to_s
			expect(pro.save).to be_truthy
		end

		description["cart_items"].each do |citem|
			cart_item = Auth.configuration.cart_item_class.constantize.new(citem)
			cart_item.resource_id = @u.id.to_s
			cart_item.resource_class = @u.class.name.to_s
			cart_item.signed_in_resource = @u
			expect(cart_item.save).to be_truthy
		end

		wrapper = Auth::System::Wrapper.new(description["wrapper"])
		expect(wrapper.save).to be_truthy
		wrapper
	end


end

RSpec.configure do |config|
	config.include SystemSupport, :type => :request
	config.include SystemSupport, :type => :model
end