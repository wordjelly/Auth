class Test
  include Mongoid::Document
  include Auth::Concerns::Shopping::ProductConcern
end
