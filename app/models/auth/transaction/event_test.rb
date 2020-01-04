class Auth::Transaction::EventTest

	 include Mongoid::Document

	 field :name, type: String

	 def does_not_return_event(args={})
	 	return []
	 end

	 def returns_nil(args={})
	 	nil
	 end



end