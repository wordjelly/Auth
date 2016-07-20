FactoryGirl.define do
  factory :client, class: Auth::Client do
    redirect_urls ["http://www.google.com"]
    user_id BSON::ObjectId.new
  end

  factory :user, class: User do 
  	email  { Faker::Internet.email }
    password  'password'
    password_confirmation  'password'
  end

  factory :user_update, class: User do 
  	email {Faker::Internet.email}
  	current_password 'password'
  end
end