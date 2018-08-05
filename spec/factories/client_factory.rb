FactoryGirl.define do


  factory :product, class: Shopping::Product do 
    name {Faker::Food.ingredient}
    price {10.00}
  end


  factory :cart_item, class: Shopping::CartItem do
    product_id {Shopping::Product.first.id.to_s}
    quantity 1
    discount_code {Faker::App.name}
    price {10.00}
    name {Faker::Food.ingredient}
    accept_order_at_percentage_of_price {0.2}
  end

  

  factory :client, class: Auth::Client do
    redirect_urls ["http://www.google.com"]
    user_id BSON::ObjectId.new
  end

  factory :user_mobile, class: User do 
    additional_login_param  {Faker::Number.between(9822028511, 9922028511).to_s}
    password  'password'
    password_confirmation  'password'
  end

  factory :user_mobile_invalid, class: User do 
    additional_login_param  {Faker::Name.name}
    password  'password'
    password_confirmation  'password'
  end

  factory :user_mobile_confirmed, class: User do
    additional_login_param  {Faker::Number.between(9822028511, 9922028511).to_s}
    password  'password'
    password_confirmation  'password'
    additional_login_param_status 2
  end


  factory :user, class: User do 
  	email  { Faker::Internet.email }
    password  'password'
    password_confirmation  'password'
  end


  factory :user_confirmed, class: User do
    email  { Faker::Internet.email }
    password  'password'
    password_confirmation  'password'
    confirmed_at Time.now
  end


  factory :user_update, class: User do 
  	email {Faker::Internet.email}
  	current_password 'password'
  end

  factory :admin, class: User do 
    email  { Faker::Internet.email }
    password  'password'
    password_confirmation  'password'
  end


  factory :admin_confirmed, class: Admin do
    email  { Faker::Internet.email }
    password  'password'
    password_confirmation  'password'
    confirmed_at Time.now
  end


  factory :step, class: Auth::Workflow::Step do 
    name {Faker::Name.name}
    description {Faker::Name.name}
  end


  factory :sop, class: Auth::Workflow::Sop do 
    name {Faker::Name.name}
    description {Faker::Name.name}
  end


  factory :assembly, class: Auth::Workflow::Assembly do 
    name {Faker::Name.name}
    description {Faker::Name.name}
  end

  factory :stage, class: Auth::Workflow::Stage do 
    name {Faker::Name.name}
    description {Faker::Name.name}
  end


  factory :add_order, class: Auth::Workflow::Order do 
    action 1
  end

  factory :requirement, class: Auth::Workflow::Requirement do 
    name {Faker::Name.name}
  end

  factory :state, class: Auth::Workflow::State do 
    name {Faker::Name.name}
  end

  factory :tlocation, class: Auth::Workflow::Tlocation do 
    name {Faker::Name.name}
  end

end
