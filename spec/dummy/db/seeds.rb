require "faker"
Shopping::CartItem.delete_all
json_tests = JSON.parse(IO.read("#{Rails.root}/lib/assets/files/test_names.json"))
counter = 0
r = Random.new
json_tests["data"].each do |test_as_array|
        t = Shopping::CartItem.new
        t.name = test_as_array[0]
        t.description = ActionView::Base.full_sanitizer.sanitize(test_as_array[1])
        t.sample_type = ActionView::Base.full_sanitizer.sanitize(test_as_array[2])
        t.price = Faker::Commerce.price
        t.accept_order_at_percentage_of_price = (r.rand(0..100)/100).to_f
        t.public = true
        ## using this to skip it having to save a cart item without the resource_class added.
        t.save
        puts "saved cart item: #{counter}"
        counter+=1
end


