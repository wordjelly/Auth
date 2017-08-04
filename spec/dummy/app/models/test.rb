class Test
  include Mongoid::Document
  include Auth::Concerns::Shopping::ProductConcern
  field :test_time, type: DateTime
end
