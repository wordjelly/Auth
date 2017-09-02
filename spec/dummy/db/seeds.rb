require "faker"
Test.delete_all
50.times do |t|
	time = DateTime.now - t.days
	
	payable_at = Test.stages.keys.sample
	cancellable_at = Test.stages.keys.sample
	
	test_object = Test.create(:name => Faker::Commerce.material, :price => Faker::Commerce.price, :test_time => time, :payable_at => payable_at, :cancellable_at => cancellable_at)
	puts "created test object:"
	puts test_object.attributes.to_s
end

