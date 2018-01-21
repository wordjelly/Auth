require "faker"

def create_cart_items
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
end

def create_users
        User.all.each do |u|
                u.destroy
        end

        20.times do 
                u = User.new
                u.email = Faker::Internet.email
                u.confirmed_at = Time.now
                u.password = "password"
                u.versioned_create
                puts u.errors.full_messages
                #puts "------------------ CREATED ---------------------------"
                u = User.find(u.id.to_s)
                u.additional_login_param = Faker::Number.between(9561137096, 9661137096).to_s
                u.additional_login_param_status = 2
                User.skip_callback(:save, :after, :send_sms_otp)
                u.versioned_update({"additional_login_param" => nil, "additional_login_param_status" => nil})
                puts u.errors.full_messages
                #puts u.attributes.to_s
        end

end


create_users