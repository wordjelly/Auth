class Auth::System::Wrapper

	include Auth::Concerns::SystemConcern
	embeds_many :levels, :class_name => "Auth::System::Level"
	
	before_save do |document|
		document.add_addresses
	end
	
	def add_cart_items
		## first add the cart items to the branches.
		_branches = []
		self.cart_item_ids.each do |cid|
			cart_item = Auth.configuration.cart_item_class.constantize.find(cid)
			self.levels.each do |level|
				level.branches.each do |branch|
					if branch.product_bunch == cart_item.product_bunch
						branch.cart_item_ids << cid
					end
				end
			end
		end
	end

	def add_addresses
		_level = 0
		self.levels.each do |level|
			level.address = "l" + _level.to_s
			_branch = 0
			level.branches.each do |branch|
				branch.address = level.address + ":b" + _branch.to_s
				branch.definitions.each do |definition|
					_definition = 0
					definition.address = branch.address + ":d" + _definition.to_s
					_creation = 0
					definition.creations.each do |creation|
						creation.address = definition.address + ":c" + _creation.to_s
						_creation+=1
					end
					_unit = 0
					definition.units.each do |unit|
						unit.address = definition.address + ":u" + _unit.to_s
						_unit+=1
					end
					_definition+=1
				end
				_branch+=1
			end
			_level+=1
		end	
	end

end