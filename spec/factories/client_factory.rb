FactoryGirl.define do

  factory :product, class:Shopping::Product do 
    name {Faker::Food.ingredient}
    price {Faker::Number.decimal(2)}
  end


  factory :cart_item, class:Shopping::CartItem do
    FactoryGirl.create(:product)
    product_id {Shopping::Product.first.id.to_s}
    quantity 1
    discount_code {Faker::App.name}
    price {Faker::Number.decimal(2)}
    name {Faker::Food.ingredient}
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

end