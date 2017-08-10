require "faker"
=begin
Test.delete_all
50.times do |t|
	time = DateTime.now - t.days
	test_object = Test.create(:name => Faker::Commerce.material, :price => Faker::Commerce.price, :test_time => time)
	puts "created test object:"
	puts test_object.attributes.to_s
end
=end
Shopping::CartItem.delete_all
Shopping::Transaction.delete_all

t = Shopping::Transaction.new
t.child_ids = []

c = Shopping::CartItem.new
c.name = "my first cart item."
c.versioned_create
puts "saving cart item op success: #{c.op_success}"
if c.op_success
	puts "saved cart item"
	t.child_ids << c.id
	puts "saving transaction"
	t.versioned_create
	puts "transaction save response: #{t.op_success.to_s}"
	puts "transaction errors"
	puts t.errors.full_messages
	puts "is the transaction a new record"
	puts t.new_record?
	
	puts "reloading the cart item., here are its attrs."
	c.reload
	puts c.attributes.to_s
else
	puts c.errors.full_messages
end
