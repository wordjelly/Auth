class Auth::Work::Input

	include Mongoid::Document

	embedded_in :cycle, :class_name => "Auth::Work::Cycle"
	
	## key -> cart_item_id
	## value -> quantity
	field :items, type: Hash, default: {}




end