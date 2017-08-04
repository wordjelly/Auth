require "faker"
Test.delete_all
50.times do |t|
	time = DateTime.now - t.days
	test_object = Test.create(:name => Faker::Commerce.material, :price => Faker::Commerce.price, :test_time => time)
	puts "created test object:"
	puts test_object.attributes.to_s
end