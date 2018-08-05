#module for helping controller specs
module ValidUserHelper
  def signed_in_as_a_valid_user
    @user ||= FactoryGirl.create :user
    sign_in @user # method from devise:TestHelpers
  end

  def signed_in_as_a_valid_admin
    @admin ||= FactoryGirl.create :admin
    sign_in @admin
  end
end

# module for helping request specs
module ValidUserRequestHelper
  include Warden::Test::Helpers

  def self.included(base)
    base.before(:each) { Warden.test_mode! }
    base.after(:each) { Warden.test_reset! }
  end

  def sign_in(resource)
    puts "came to sign in resource."
    login_as(resource, scope: warden_scope(resource))
  end

  def sign_out(resource)
    logout(warden_scope(resource))
  end

  private

  def warden_scope(resource)
    resource.class.name.underscore.to_sym
  end

  def sign_in_as_a_valid_admin
    @admin = FactoryGirl.create :admin
    cli = Auth::Client.new
    cli.current_app_id = "test_app_id"
    @admin.set_client_authentication(cli)
    @admin.save!
    post_via_redirect admin_session_path, 'admin[email]' => @admin.email, 'admin[password]' => @admin.password
  end

  def sign_in_as_a_valid_and_confirmed_admin
    @admin = Admin.new(attributes_for(:admin_confirmed))
    @admin.versioned_create
    sign_in(@admin)
  end
  
  

  def sign_in_as_a_valid_and_confirmed_user
    @user = User.new(attributes_for(:user_confirmed))
    @user.versioned_create
    sign_in(@user)
  end

end

module AdminRootPathSupport
  ##this needs to be done ,because after_sign_in_path_for has been changed for admin in the application_controller, to topics/new.
  def admin_after_sign_in_path
    app.routes.url_helpers.new_topic_url(:only_path => true)
  end
end


module RequirementQueryHashSupport

  ## @param[String] json_file_path : the path to the json file which holds the assembly definition.
  ## @param[Boolean] document_is_root : defaults to true, if false, will consider the assembly to be specified at the 'assembly' key in the json file. 
  def load_assembly_from_json(json_file_path,document_is_root=true)
    assembly_as_hash = JSON.parse(IO.read(json_file_path))
    assembly_as_hash = document_is_root ? assembly_as_hash : assembly_as_hash["assembly"]
    assembly = Auth.configuration.assembly_class.constantize.new(assembly_as_hash)
    ## just return the assembly as is.
    return assembly
  end

  
  def build_and_save_products(n,admin)
    products = []
    n.times do |t|
      product = Auth.configuration.product_class.constantize.new(price: 300, resource_id: admin.id.to_s, resource_class: admin.class.name, signed_in_resource: admin)
       expect(product.save).to be_truthy
       products << product
    end 
    products
  end


  def build_and_save_cart_items(products,user)
    cart_items = []
    products.each do |product|
      c = Auth.configuration.cart_item_class.constantize.new(product_id: product.id.to_s, resource_id: user.id.to_s, resource_class: user.class.name, signed_in_resource: user)
      
      expect(c.save).to be_truthy
      cart_items << c
    end

    cart_items
  end


  ## @param[String] file_path : the path of the file from where load the  
  ## @param[Auth::User] admin : an admin user
  ## @param[Auth::User] user : a normal user
  ## @return[Hash] a response hash containing three keys : assembly, cart_items and schedules, all created and persisted to the database.
  def load_and_create_schedules_bookings_and_requirements(file_path,admin,user)

    loaded_assembly = load_assembly_from_json(file_path,false)
    response  = update_assembly_with_products_and_create_cart_items(loaded_assembly,admin,user)

    schedules_array = JSON.parse(IO.read(file_path))["schedules"]
    requirements_to_build = {}
    schedules = schedules_array.each_with_index.map{|c,i|
      c = Auth.configuration.schedule_class.constantize.new(c)
      expect(c.save).to be_truthy
      c
    }

    return response.merge(:schedules => schedules)

  end

  def update_assembly_with_products_and_create_cart_items(loaded_assembly,admin,user)

    products_to_build = {}
    products_built = {}
    locations_to_build = {}
    
    ## we need the new ids assinged for the requirements.

    loaded_assembly.stages.each_with_index {|stage,stage_index|
      stage.sops.each_with_index {|sop,sop_index|
        sop.applicable_to_product_ids.each_with_index {|p_id,p_index|
          products_to_build[p_id] = [] unless products_to_build.include? p_id
          products_to_build[p_id] << [stage_index,sop_index,p_index]
        }
        sop.steps.each_with_index {|step,step_index|
          if location_id = step.location_information["location_id"]
            locations_to_build[location_id] = [] unless locations_to_build[location_id]
            locations_to_build[location_id] << [stage_index,sop_index,step_index] 
          end
          ## otherwise if the location information has some latitude and longitued and with our without categories.
          ## then it can directly create location objects out of it.
          ## and nothing needs to be replaced in the assembly.
          ## modulate the lat long slightly.
          if step.location_information["location_point_coordinates"]
           # puts "the location information is:"
           # puts step.location_information
            lat = step.location_information["location_point_coordinates"]["lat"]
            lng = step.location_information["location_point_coordinates"]["lng"]
            location_obj = Auth.configuration.location_class.constantize.new(location: {:lat => lat - 0.01, :lng => lng + 0.01})
            location_obj.location_categories = step.location_information["location_categories"] if step.location_information["location_categories"]

            #puts "the location obj is:"
            #puts location_obj.attributes.to_s

            expect(location_obj.save).to be_truthy
          end
        }
      }
    }

    
    locations_to_build.keys.each do |l_id|
      location = Auth.configuration.location_class.constantize.new(location: {:lat => 10.0, :lng => 15.0}, location_categories: ["hematology_station","biochemistry_station"])
      expect(location.save).to be_truthy
      locations_to_build[l_id].each do |address|
        loaded_assembly.stages[address[0]].sops[address[1]].steps[address[2]]["location_information"]["location_id"] = location.id.to_s
      end
    end


    
    products_to_build.keys.each do |p_id|
      product = Auth.configuration.product_class.constantize.new(price: 300, resource_id: admin.id.to_s, resource_class: admin.class.name, signed_in_resource: admin)
      expect(product.save).to be_truthy
      products_to_build[p_id].each do |address|
        loaded_assembly.stages[address[0]].sops[address[1]].applicable_to_product_ids[address[2]] = product.id.to_s
      end
      products_built[product.id.to_s] = product
    end

    puts loaded_assembly.errors.full_messages unless loaded_assembly.save

    cart_items = products_built.keys.map{|p_id|
      c = Auth.configuration.cart_item_class.constantize.new(product_id: p_id, resource_id: user.id.to_s, resource_class: user.class.name, signed_in_resource: user)
      
      expect(c.save).to be_truthy

      p_id = c
    }

    {assembly: loaded_assembly, products: products_built, cart_items: cart_items}

  end


  ## the stops can be the different steps in the pipeline which you want returned.
  ## they have to be the name of the functions called in the pipeline.
  def pipeline(stops,a,cart_items)
    
    pipeline_results = {}

    options = {}

    options[:order] = Auth.configuration.order_class.constantize.new(:cart_item_ids => cart_items.map{|c| c = c.id.to_s}).to_json

    search_sop_events = a.clone_to_add_cart_items(options)
    
    #expect(search_sop_events.size).to eq(1)

    pipeline_results[:search_sop_events] = search_sop_events if stops[:search_sop_events]
    
    return pipeline_results unless search_sop_events.size > 0

    create_order_events = search_sop_events.first.process
    
    #expect(create_order_events.size).to eq(1)

    pipeline_results[:create_order_events] = create_order_events if stops[:create_order_events]
    
    return pipeline_results unless create_order_events.size > 0

    schedule_sop_events = create_order_events.first.process
    
    #expect(schedule_sop_events.size).to eq(1)
    
    pipeline_results[:schedule_sop_events] = schedule_sop_events if stops[:schedule_sop_events]

    return pipeline_results unless schedule_sop_events.size > 0

    after_schedule_sop = schedule_sop_events.first.process
    
    #expect(after_schedule_sop.size).to eq(1)
    
    after_schedule_sop = after_schedule_sop.first
    
    pipeline_results[:after_schedule_sop] = after_schedule_sop if stops[:after_schedule_sop]

    pipeline_results

  end


end



module SpecificationSupport

  ## @return[Array] cart_items : array of cart items loaded from the json file specified in json_file_path. Each cart item is given its own product. It also creates the location objects if any location ids are specified inside the specifications.
  def load_cart_items_from_json(json_file_path)

    root = JSON.parse(IO.read(json_file_path))

    cart_items_hashes = root["cart_items"]
    
    cart_items = []

    cart_items_hashes.each do |citem_hash|
      c = Auth.configuration.cart_item_class.constantize.new(citem_hash)
      c.signed_in_resource = @u
      c.resource_id = @u.id.to_s
      c.resource_class = @u.class.name.to_s
      ## whatever is the product id, make one like that
      product = Auth.configuration.product_class.constantize.new
      product.signed_in_resource = @admin
      product.resource_id = @admin.id.to_s
      product.resource_class = @admin.class.name.to_s
      expect(product.save).to be_truthy
      c.product_id = product.id.to_s
      expect(c.save).to be_truthy
      cart_items << c
    end


    locations = {}


    cart_items.each do |citem|
      citem.specifications.each do |spec|
        location_ids_actual = {}
        if spec.permitted_location_ids.size > 0
          spec.permitted_location_ids.each_with_index {|lid,k|
            if locations[lid]

            else
              l = Auth.configuration.location_class.constantize.new
              expect(l.save).to be_truthy
              locations[lid] = l
            end     
          }

          spec.permitted_location_ids.map{|c| c = locations[c]}
         
          spec.permitted_location_ids.map{|c| c = locations[c]} if spec.permitted_location_ids
          
        end
      end
      expect(citem.save).to be_truthy
    end

    cart_items

  end

end

module DiscountSupport
  
  def create_cart_items(signed_in_res,user=nil,number=5,price=10.0)
    cart_items = []
    user ||= signed_in_res
    number.times do             
        cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
        cart_item.resource_id = user.id.to_s
        cart_item.resource_class = user.class.name
        cart_item.product_id = Shopping::Product.first.id.to_s
        cart_item.price = Shopping::Product.first.price
        cart_item.signed_in_resource = signed_in_res
        cart_items << cart_item if cart_item.save
    end
    return cart_items 
  end

  def create_cart(signed_in_res,user=nil)
    user ||= signed_in_res

    cart = Shopping::Cart.new
    cart.signed_in_resource = signed_in_res
    cart.resource_id = user.id.to_s
    cart.resource_class = user.class.name
    puts "result of creating cart."
    puts cart.save.to_s
    puts "cart create errors."
    puts cart.errors.full_messages.to_s
    return cart
  end

  def add_cart_items_to_cart(cart_items,cart,signed_in_res,user=nil)
    user ||= signed_in_res
    k = cart_items.map{|citem|
      citem.signed_in_resource = signed_in_res
      citem.parent_id = cart.id.to_s
      citem.save
    }.select{|c| c == false}.size == 0
    puts "result of adding cart items to cart"
    puts k.to_s
    k
  end

  def create_payment(cart,amount,signed_in_res,type="cash",user=nil)
    user ||= signed_in_res
    payment = Shopping::Payment.new
    payment.amount = amount
    payment.cart_id = cart.id.to_s
    payment.payment_type = type
    payment.signed_in_resource = signed_in_res
    payment.resource_id = user.id
    payment.resource_class = user.class.name
    d = payment.save
    puts "result of saving payemnt #{d.to_s}"
    puts payment.errors.full_messages.to_s
    payment
  end

  def authorize_payment_as_admin(payment,admin)
    payment.signed_in_resource = admin
    payment.payment_status = 1
    res = payment.save
    puts "Result of saving payment is: #{res}"
    puts payment.errors.full_messages.to_s
  end

  def build_discount_for_request(cart)
    cart.prepare_cart
    discount = Shopping::Discount.new
    discount.requires_verification = true
    discount.cart_id = cart.id.to_s
    discount.discount_amount = cart.cart_paid_amount
    discount.product_ids = cart.cart_items.map{|c| c = c.product_id}
    discount
  end

  def build_cartless_productless_discount
    discount = Shopping::Discount.new
    discount.discount_percentage = 100
    discount.discount_amount = 10
    discount.count = 4
    discount
  end

  def create_cartless_productless_discount(signed_in_res,user=nil)

    user||= signed_in_res
    discount = Shopping::Discount.new
    discount.discount_percentage = 100
    discount.discount_amount = 10
    discount.count = 4
    discount.signed_in_resource = signed_in_res
    discount.resource_id = user.id.to_s
    discount.resource_class = user.class.name
    res = discount.save
    puts "result of saving discount: #{res.to_s}"
    puts "errors while saving discount.."
    puts discount.errors.full_messages.to_s
    discount
  end

  def create_discount(cart,signed_in_res,user=nil,req_ver=true)
    cart.prepare_cart
    user ||= signed_in_res
    discount = Shopping::Discount.new
    discount.requires_verification = req_ver
    discount.cart_id = cart.id.to_s
    discount.discount_amount = cart.cart_paid_amount
    discount.resource_id = user.id.to_s
    discount.resource_class = user.class.name
    discount.signed_in_resource = signed_in_res
    discount.product_ids = cart.cart_items.map{|c| c = c.product_id}
    res = discount.save
    puts "discount save response: #{res.to_s}"
    puts "create discount errors:"
    puts discount.errors.full_messages
    discount
  end

  def create_multiple_cart_items(discount,signed_in_res,user = nil)

    user ||= signed_in_res

    created_multiple_cart_items = discount.product_ids.map{|pid|
      c = Shopping::CartItem.new
      c.product_id = pid
      c.signed_in_resource = signed_in_res
      c.resource_id = user.id.to_s
      c.resource_class = user.class.to_s
      #puts "multiple cart save response:"
      l = c.save
      #puts l.to_s
      #puts l.errors.full_messages.to_s
      c
    }

    created_multiple_cart_items

  end

  def create_payment_using_discount(discount,cart,signed_in_res,user = nil)
    
    user ||= signed_in_res
    payment = Shopping::Payment.new
    payment.signed_in_resource = signed_in_res
    payment.resource_id = user.id.to_s
    payment.resource_class = user.class.name
    payment.amount = 0.0
    payment.cart_id = cart.id.to_s
    payment.discount_id = discount.id.to_s
    payment.payment_type = "cash"
    res = payment.save
    puts " ------------ Look here ---------------------------"
    puts "Result of saving payment"
    puts res.to_s
    puts "errors saving payment:"
    puts payment.errors.full_messages
    payment

  end

  def approve_pending_discount_request(discount,pending_payment,signed_in_res,user=nil)

    user||= signed_in_res

    dis = Shopping::Discount.find(discount.id.to_s)
    dis.verified << pending_payment.id.to_s
    dis.pending.delete(pending_payment.id.to_s)
    dis.signed_in_resource = signed_in_res
    res = dis.save  
    puts "Result of saving discount"
    puts res.to_s
    puts "errors saving payment:"
    puts dis.errors.full_messages
    dis

  end

  def use_discount(discount_payment,signed_in_res,user=nil)
     user ||= signed_in_res
     discount_payment.signed_in_resource = signed_in_res
     res = discount_payment.save
     puts "result of saving payment: #{res.to_s}"
     puts "the errors of saving discount payment."
     puts discount_payment.errors.full_messages.to_s
     discount_payment
  end


  def update_payment_as_failed(payment,signed_in_res,user=nil)
    user ||= nil
    payment.signed_in_resource = signed_in_res
    payment.payment_status = 0
    res = payment.save
    puts "result of saving payment: #{res.to_s}"
    puts "the errors of saving payment."
    puts payment.errors.full_messages.to_s
    payment
  end

end

module AdminCreateUserSupport

  ## @param[Implements Auth::UserConcern] user_created : a resource that was just created.
  ## @return[String] session_id:  the id of the session generated by the twofactorotp library in redis.
  def get_otp_session_id(user_created)
    session_id = $redis.hget(user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
    session_id
  end

  def create_user_with_mobile
    u = User.new
    u.additional_login_param = "9561137096"
    u.password = u.password_confirmation = SecureRandom.hex(24)
    u.created_by_admin = true
    u.save
    u
  end

  ## just sets the additional_login_param_status to 2.
  def verify_user_mobile(user_created)
    user_created.additional_login_param_status = 2
    user_created.otp = 123456
    user_created.save
    user_created
  end

  def unverify_user_mobile(user_created)
    user_created.additional_login_param_status = 0
    user_created.otp = 123455
    user_created.save
    user_created
  end

  def update_mobile_number(user_created)
    user_created.additional_login_param = "9612344556"
    user_created.save
  end

  ## @return[String] confirmation_token.
  def get_confirmation_token_from_email
    message = ActionMailer::Base.deliveries[-1].to_s
    confirmation_token = nil
    message.scan(/confirmation_token=(?<confirmation_token>.*)\"/) do |ll|
      j = Regexp.last_match
      confirmation_token = j[:confirmation_token]
    end    
    confirmation_token
  end

  def create_user_with_email
    u = User.new
    u.email = "rrphotosoft@gmail.com"
    u.password = u.password_confirmation = SecureRandom.hex(24)
    u.created_by_admin = true
    u.save
    u
  end

  def get_reset_password_token_from_email(position = -1)
    message = ActionMailer::Base.deliveries[position].to_s
    reset_password_token = nil
    message.scan(/reset_password_token=(?<reset_password_token>.*)\"/) do |ll|
      j = Regexp.last_match
      reset_password_token = j[:reset_password_token]
    end    
    reset_password_token
  end

  def verify_user_email(user_created)
    user_created.confirm
    user_created.save
  end

  def update_user_email(user_created)
    user_created.email = "doctor@gmail.com"
    user_created.save
  end

end



module WorkflowSupport

  def create_assembly_with_stages_sops_and_steps
    assembly = Auth::Workflow::Assembly.new(attributes_for(:assembly))
    assembly.stages = [Auth::Workflow::Stage.new]
    assembly.stages[0].name = "first stage"
    assembly.stages[0].sops = [Auth::Workflow::Sop.new]
    assembly.stages[0].sops[0].steps = [Auth::Workflow::Step.new]
    assembly
  end

  def create_assembly_with_stage_sops_and_order
    assembly = Auth::Workflow::Assembly.new(attributes_for(:assembly))
    assembly.stages = [Auth::Workflow::Stage.new]
    assembly.stages[0].name = "first stage"
    assembly.stages[0].sops = [Auth::Workflow::Sop.new]
    assembly.stages[0].sops[0].orders = [Auth::Workflow::Order.new]
    assembly.stages[0].sops[0].orders[0].action = 1
    puts assembly.stages[0].sops[0].orders[0].valid?
    puts assembly.stages[0].sops[0].orders[0].errors.full_messages
    puts assembly.stages[0].sops[0].valid?
    puts assembly.stages[0].sops[0].errors.full_messages
    puts assembly.stages[0].valid?
    puts assembly.stages[0].errors.full_messages
    assembly
  end

  def create_assembly_with_stages_sops_steps_and_requirements
    assembly = Auth::Workflow::Assembly.new(attributes_for(:assembly))
    assembly.stages = [Auth::Workflow::Stage.new]
    assembly.stages[0].name = "first stage"
    assembly.stages[0].sops = [Auth::Workflow::Sop.new]
    assembly.stages[0].sops[0].steps = [Auth::Workflow::Step.new]
    assembly.stages[0].sops[0].steps[0].requirements = [Auth::Workflow::Requirement.new]
    assembly
  end

  def create_assembly_with_stages_sops_steps_and_tlocations
    assembly = Auth::Workflow::Assembly.new(attributes_for(:assembly))
    assembly.stages = [Auth::Workflow::Stage.new]
    assembly.stages[0].name = "first stage"
    assembly.stages[0].sops = [Auth::Workflow::Sop.new]
    assembly.stages[0].sops[0].steps = [Auth::Workflow::Step.new]
    assembly.stages[0].sops[0].steps[0].tlocations = [Auth::Workflow::Tlocation.new]
    assembly
  end

  def create_assembly_with_stages_sops_steps_requirements_and_states
    assembly = Auth::Workflow::Assembly.new(attributes_for(:assembly))
    assembly.stages = [Auth::Workflow::Stage.new]
    assembly.stages[0].name = "first stage"
    assembly.stages[0].sops = [Auth::Workflow::Sop.new]
    assembly.stages[0].sops[0].steps = [Auth::Workflow::Step.new]
    assembly.stages[0].sops[0].steps[0].requirements = [Auth::Workflow::Requirement.new]
    assembly.stages[0].sops[0].steps[0].requirements[0].states = [Auth::Workflow::State.new]
    assembly
  end

  def create_empty_assembly
    assembly = Auth::Workflow::Assembly.new(attributes_for(:assembly))
    assembly
  end

  def create_empty_stage
    stage = Auth::Workflow::Stage.new(attributes_for(:stage))
    stage
  end

  def create_empty_sop
    sop = Auth::Workflow::Sop.new(attributes_for(:sop))
    sop
  end

  def create_empty_step
    step = Auth::Workflow::Step.new(attributes_for(:step))
    step
  end

  def create_products(n,user,admin)
    products = []
    n.times do |t|
        product_one = Auth::Shopping::Product.new
        product_one.resource_id = user.id.to_s
        product_one.resource_class = user.class.name.to_s
        product_one.signed_in_resource = admin
        product_one.save
        products << product_one
    end
    products
  end

  def create_order_into_sop(assembly,stage,sop)

    order = attributes_for(:add_order)
    order[:cart_item_ids] = [BSON::ObjectId.new.to_s, BSON::ObjectId.new.to_s]
    order[:assembly_id] = assembly.id.to_s
    order[:assembly_doc_version] = assembly.doc_version
    order[:stage_id] = stage.id.to_s
    order[:stage_doc_version] = stage.doc_version
    order[:stage_index] = 0
    order[:sop_id] = sop.id.to_s
    order[:sop_doc_version] = sop.doc_version
    order[:sop_index] = 0
    order = Auth.configuration.order_class.constantize.new(order)
    
    assembly.stages[0].sops[0].orders << order

    order.valid?
    
    res = assembly.save

    return order if res

  end

  ###########################################################
  ##
  ##
  ## common definitions.
  ##
  ##
  ###########################################################


  def add_assembly_info_to_object(assembly,object_attributes_hash)
  
    object_attributes_hash[:assembly_id] = assembly.id.to_s
    
    object_attributes_hash[:assembly_doc_version] = assembly.doc_version

  end


  def add_sop_info_to_object(assembly,stage,sop,object_attributes_hash)
    
    object_attributes_hash[:sop_id] = sop.id.to_s
    
    object_attributes_hash[:sop_doc_version] = sop.doc_version
    
    assembly.stages.each_with_index{|stg,stage_key|
      if stage.id.to_s == stg.id.to_s
        stg.sops.each_with_index{|sp,sop_key|
          if sp.id.to_s == sop.id.to_s
            object_attributes_hash[:sop_index] = sop_key
          end
        }
      end
    }

  end

  def add_stage_info_to_object(assembly,stage,object_attributes_hash)
    object_attributes_hash[:stage_id] = stage.id.to_s
    object_attributes_hash[:stage_doc_version] = stage.doc_version
    
    assembly.stages.each_with_index{|stg,key|
      object_attributes_hash[:stage_index] = key if stage.id.to_s == stg.id.to_s
    }

  end

  def add_step_info_to_object(assembly,stage,sop,step,object_attributes_hash)
   
    object_attributes_hash[:step_id] = step.id.to_s
    object_attributes_hash[:step_doc_version] = step.doc_version
    

    assembly.stages.each_with_index{|stg,stage_key|
      if stage.id.to_s == stg.id.to_s
        stg.sops.each_with_index{|sp,sop_key|
          if sp.id.to_s == sop.id.to_s
            sp.steps.each_with_index{|st,step_key|
              if st.id.to_s == step.id.to_s
                object_attributes_hash[:step_index] = step_key
              end
            }
          end
        }
      end
    }

  end

  def add_order_info_to_object(assembly,stage,sop,order,object_attributes_hash)
   
    object_attributes_hash[:order_id] = order.id.to_s
    object_attributes_hash[:order_doc_version] = order.doc_version
    

    assembly.stages.each_with_index{|stg,stage_key|
      if stage.id.to_s == stg.id.to_s
        stg.sops.each_with_index{|sp,sop_key|
          if sp.id.to_s == sop.id.to_s
            sp.orders.each_with_index{|ord,ord_key|
              if ord.id.to_s == order.id.to_s
                object_attributes_hash[:order_index] = ord_key
              end
            }
          end
        }
      end
    }

  end


  def add_requirement_info_to_object(assembly,stage,sop,step,requirement,object_attributes_hash)

    object_attributes_hash[:requirement_id] = requirement.id.to_s
    object_attributes_hash[:requirement_doc_version] = requirement.doc_version
    

    assembly.stages.each_with_index{|stg,stage_key|
      if stage.id.to_s == stg.id.to_s
        stg.sops.each_with_index{|sp,sop_key|
          if sp.id.to_s == sop.id.to_s
            sp.steps.each_with_index{|st,step_key|
              if st.id.to_s == step.id.to_s
                st.requirements.each_with_index{|rq,rq_key|
                  if rq.id.to_s == requirement.id.to_s 
                    object_attributes_hash[:requirement_index] = rq_key
                  end
                }
              end
            }
          end
        }
      end
    }

  end

  def add_tlocation_info_to_object(assembly,stage,sop,step,tlocation,object_attributes_hash)

    object_attributes_hash[:tlocation_id] = tlocation.id.to_s
    object_attributes_hash[:tlocation_doc_version] = tlocation.doc_version
    

    assembly.stages.each_with_index{|stg,stage_key|
      if stage.id.to_s == stg.id.to_s
        stg.sops.each_with_index{|sp,sop_key|
          if sp.id.to_s == sop.id.to_s
            sp.steps.each_with_index{|st,step_key|
              if st.id.to_s == step.id.to_s
                st.tlocations.each_with_index{|rq,rq_key|
                  if rq.id.to_s == tlocation.id.to_s 
                    object_attributes_hash[:tlocation_index] = rq_key
                  end
                }
              end
            }
          end
        }
      end
    }

  end

  def add_state_info_to_object(assembly,stage,sop,step,requirement,state,object_attributes_hash)

    object_attributes_hash[:state_id] = state.id.to_s
    object_attributes_hash[:state_doc_version] = state.doc_version
    

    assembly.stages.each_with_index{|stg,stage_key|
      if stage.id.to_s == stg.id.to_s
        stg.sops.each_with_index{|sp,sop_key|
          if sp.id.to_s == sop.id.to_s
            sp.steps.each_with_index{|st,step_key|
              if st.id.to_s == step.id.to_s
                st.requirements.each_with_index{|rq,rq_key|
                  if rq.id.to_s == requirement.id.to_s 
                    rq.states.each_with_index {|st,st_key|
                      if st.id.to_s == state.id.to_s
                        object_attributes_hash[:state_index] = st_key
                      end
                    }
                  end
                }
              end
            }
          end
        }
      end
    }

  end

end

module OrderCreationFlow

  ## will create @cart_item_count cart_items, and save them.
  ## will also create an assembly, set it as master, and add the product_id of the first cart_item will be added to the first sop of the first stage of the assembly, as an applicable product id.
  ## if @add_product_ids_to_sop is false, it will not add any product ids to the sop, this is used to simulate the situation where no matching sops are found for the provided cart_item_ids in #sop_model_spec.rb
  ## @return[Hash] : two keys : cart_items, and assembly, carrying the respective array of cart_items, and an assembly.
  def create_cart_items_assembly_sops_with_product_ids(user,cart_item_count=2,add_product_ids_to_sop=true)

    cart_items = create_cart_items(user,nil,2)
    ## create an empty assembly with stages,sops and steps.
    assembly = create_assembly_with_stages_sops_and_steps
    assembly.stages[0].applicable = true
    assembly.stages[0].sops[0].applicable = true
    assembly.master = true
    assembly.applicable = true
    ## add one cart item to each sop.
    if add_product_ids_to_sop
      assembly.stages[0].sops[0].applicable_to_product_ids = [cart_items.map{|c| c = c.product_id}.first]
    end

    res = assembly.save
    return nil if ((cart_items.size < cart_item_count) || res == false)
    return {:cart_items => cart_items, :assembly => assembly}

  end

  ## the step is added to the first sop.
  ## adds one step, with two requirements, and adds one state to each requirement 
  def add_steps_requirements_states_to_assembly(assembly,products)
    
    ##########################################################
    ##
    ## STATES
    ##
    ##########################################################    
    state_for_requirement_one = Auth.configuration.state_class.constantize.new
    state_for_requirement_one.applicable = true
   
    state_for_requirement_one.setter_function = "
      cart_items = order.cart_item_ids.map{|c_id|
        c_id = Auth.configuration.cart_item_class.constantize.find(c_id.to_s)
      }
      self.required_value = 0
      cart_items.map{|citem|
        if citem.class.method_defined?(:heatable) 
          if citem.heatable == true
            self.required_value+=30
          end
        end
      }
    "

    state_for_requirement_two = Auth.configuration.state_class.constantize.new
    state_for_requirement_two.applicable = true

    #########################################################
    ##
    ## REQUIREMENTS
    ##
    ## the requirements have to have their own product ids.
    ## basicallyt these products have to exist.
    #########################################################
    ## for that here we have to also pass in some products, and we choose randomly from them.

    requirement_one = Auth.configuration.requirement_class.constantize.new
    requirement_one.applicable = true
    requirement_one.product_id = products.first.id.to_s
    requirement_one.states << state_for_requirement_one
    
    requirement_two = Auth.configuration.requirement_class.constantize.new
    requirement_two.product_id =products.last.id.to_s
    requirement_two.applicable = true
    requirement_two.states << state_for_requirement_two

    #########################################################
    ##
    ## STEPS
    ##
    #########################################################

    step = Auth.configuration.step_class.constantize.new
    step.applicable = true
    step.duration = 300
    step.requirements = [requirement_one,requirement_two]


    assembly.stages[0].sops[0].steps << step
    assembly

  end

  ## options supported :
  ## :products => {"product_id" => "applicable_to_sop_address"}, required, will throw error if not provided.
  ## :sops => number of sops to be created, in each stage, defaults to 1
  ## :stages => number of stages to be created, defaults to 1
  ## :steps => number of steps to be created in each sop, defaults to 1
  ## :requirements => number of requirements to be created in each step, defaults to 1
  ## :requirement_products => {"product_id" => "applicable_to_requirement_address"}, required, will throw error if not provided.
  ## :step_duration => will be defaulted to 500 for all steps, otherwise whatever is provided, but is applied to all steps the same.
  ## return [Hash] : :assembly => the assembly, and :errors => if either the options[:products] or options[:requirement_products] could not be added at the defined address.
  def create_assembly_with_options(options={})
    return {:errors => ["products key is missing"]} if options[:products].blank?
    products = options[:products]
    
    return {:errors => ["requirements_products key is missing"]} if options[:requirements_products].blank?
    requirement_products = options[:requirements_products]

    sops = options[:sops] || 1
    stages =  options[:stages] || 1
    steps = options[:steps] || 1
    requirements = options[:requirements] || 1
    step_duration = options[:step_duration] || 400


    errors = []

    ## now create the assembly.
    assembly = Auth::Workflow::Assembly.new
    assembly.applicable = true
    stages.times do |n|
      s = Auth::Workflow::Stage.new
      s.applicable = true
      sops.times do |n_sop|
        sop = Auth::Workflow::Sop.new
        sop.applicable = true
          steps.times do |n_steps|
            step = Auth::Workflow::Step.new
            step.duration = step_duration
            step.applicable = true
              requirements.times do |n_req|
                req = Auth::Workflow::Requirement.new
                req.applicable = true
                step.requirements << req
              end
            sop.steps << step
          end
        s.sops << sop
      end
      #puts "Adding stage: #{s}"
      assembly.stages << s
    end

    #puts assembly.stages.to_s


    products.each do |product_id, addresses|
      addresses.each do |address|
        add = address.split(".").map{|c| c = c.to_i}
        begin
         
          assembly.stages[add[0]].sops[add[1]].applicable_to_product_ids << product_id
        rescue => e
          
          errors << "address: #{address} does not exist for product id : #{product_id}"
        end
      end
    end

    requirement_products.each do |product_id, addresses|
       addresses.each do |address|
        add = address.split(".").map{|c| c = c.to_i}
        break if add.size < 3
        errors << "the address does not have enough compnoents" if add.size < 3
        begin
          assembly.stages[add[0]].sops[add[1]].steps[add[2]].requirements[add[3]].product_id = product_id
        rescue
          #puts "REQUIREMENT ERROR."
          errors << "address: #{address} does not exist for product id : #{product_id}"
        end
      end
    end

    return {:errors => errors, :assembly => assembly}

  end

end

module SearchSupport
  def contains_product?(search_results)
    response = false
    search_results.each do |result|
      begin
        product = Auth.configuration.product_class.constantize.new(result)
        response = true if product.tags.include? "product"
      rescue
      end
    end
    response
  end

  def contains_cart_item?(search_results)
    response = false
    search_results.each do |result|
      begin
        cart_item = Auth.configuration.cart_item_class.constantize.new(result)
        response = true if cart_item.tags.include? "item"
      rescue
      end
    end
    response
  end

  def contains_user?(search_results)
    response = false
    search_results.each do |result|
      begin
        user = User.new(result)
        response = true if user.tags.include? "user"
      rescue
      end
    end
    response
  end
end

RSpec.configure do |config|
  
  config.include ValidUserHelper, :type => :controller
  config.include ValidUserRequestHelper, :type => :request
  config.include AdminRootPathSupport, :type => :request
  config.include DiscountSupport, :type => :request
  config.include AdminCreateUserSupport, :type => :request
  
  config.include ValidUserRequestHelper, :type => :model
  config.include AdminRootPathSupport, :type => :model
  config.include DiscountSupport, :type => :model
  config.include AdminCreateUserSupport, :type => :model
  
  config.include WorkflowSupport, :type => :request
  config.include WorkflowSupport, :type => :model

  config.include OrderCreationFlow, :type => :request
  config.include OrderCreationFlow, :type => :model

  config.include RequirementQueryHashSupport, :type => :request
  config.include RequirementQueryHashSupport, :type => :model

  config.include SpecificationSupport, :type => :request
  config.include SpecificationSupport, :type => :model

  config.include SearchSupport, :type => :request
  config.include SearchSupport, :type => :model
  

end

