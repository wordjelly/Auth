require "faker"


def create_assembly_test_data
    Auth::Workflow::Assembly.delete_all
    assembly = Auth::Workflow::Assembly.new
    3.times do |st|
      stage = Auth::Workflow::Stage.new
      stage.name = Faker::Name.name
      3.times do |so|
        sop = Auth::Workflow::Sop.new
        sop.name = Faker::Name.name
        3.times do |st|
          step = Auth::Workflow::Step.new
          step.name = Faker::Name.name
          sop.steps << step
        end
        stage.sops << sop
      end
      assembly.stages << stage
    end
    assembly.name = "PARENT ASSEMBLY"
    puts JSON.pretty_generate(assembly.attributes)
    puts "saving.."
    puts assembly.save
  end

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


def create_bullets(n)
    bullets = []
    n.times do |b_n|
        b = Auth::Work::Bullet.new
        b.text = Faker::Food.ingredient
        bullets << b
    end
    bullets
end

def create_instructions(n,bullets_n)
    instructions = []
    n.times do |i_n|
        i = Auth::Work::Instruction.new
        i.title = Faker::Food.dish
        i.include_in_summary = true
        if i_n == 0
            i.summary_icon_class = ""
            i.summary_icon_color = ""
            i.summary_text = "Report in 30 mins"
        elsif i_n == 1
            i.summary_icon_class = ""
            i.summary_icon_color = ""
            i.summary_text = "You can watch your test being peformed"
        elsif i_n == 2
        elsif i_n == 3
        elsif i_n == 4
        end
        i.bullets = create_bullets(bullets_n)
        i.instruction_type = Auth::Work::Instruction::INSTRUCTION_TYPES.sample
        instructions << i
    end
    instructions
end 

def create_products
    Auth.configuration.product_class.constantize.delete_all
    User.delete_all
    admin_user = User.new
    admin_user.email = "joshi@gmail.com"
    admin_user.confirmed_at = Time.now
    admin_user.password = "password"
    admin_user.admin = true
    puts "result of creating user #{admin_user.save}"

=begin
    10.times do |n|
        product = Auth.configuration.product_class.constantize.new
        product.name = Faker::Food.spice
        product.badge_text = "Report in 30 mins"
        product.resource_class = admin_user.class.name
        product.resource_id = admin_user.id.to_s
        product.price = Faker::Number.between(10, 500)
        product.instructions = create_instructions(5,2)
        puts "response of saving: #{product.id.to_s} : #{product.save}"
    end
=end


    products_json_definition = JSON.parse(IO.read("#{Rails.root}/db/products.json"))
    products = products_json_definition["products"].map{|c| c = Auth.configuration.product_class.constantize.new(c)}
    products.map!{|c| 
        c.resource_class = admin_user.class.name
        c.resource_id = admin_user.id.to_s
        puts "response of saving: #{c.id.to_s} : #{c.save}" 
    }

    ## now we have three products, lets see how they get shown in the index.
    puts "user count"
    puts User.all.count

end


create_products


## so need a route to see all the products and then see a particular product
## also need a user to sign up with.