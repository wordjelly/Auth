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
        puts "cart item create errors."
        puts cart_item.errors.full_messages.to_s
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

  def create_assembly_with_stages_sops_steps_and_requirements
    assembly = Auth::Workflow::Assembly.new(attributes_for(:assembly))
    assembly.stages = [Auth::Workflow::Stage.new]
    assembly.stages[0].name = "first stage"
    assembly.stages[0].sops = [Auth::Workflow::Sop.new]
    assembly.stages[0].sops[0].steps = [Auth::Workflow::Step.new]
    assembly.stages[0].sops[0].steps[0].requirements = [Auth::Workflow::Requirement.new]
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

    return order if assembly.save

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

  def add_requirement_info_to_object(assembly,stage,sop,step,requirement,object_attributes_hash)

    object_attributes_hash[:requirement_id] = step.id.to_s
    object_attributes_hash[:requirement_doc_version] = step.doc_version
    

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

end

RSpec.configure do |config|
  
  config.include ValidUserHelper, :type => :controller
  config.include ValidUserRequestHelper, :type => :request
  config.include AdminRootPathSupport, :type => :request
  config.include DiscountSupport, :type => :request
  config.include AdminCreateUserSupport, :type => :request
  config.include WorkflowSupport, :type => :request
  config.include ValidUserRequestHelper, :type => :model
  config.include AdminRootPathSupport, :type => :model
  config.include DiscountSupport, :type => :model
  config.include AdminCreateUserSupport, :type => :model
  config.include WorkflowSupport, :type => :model

end

