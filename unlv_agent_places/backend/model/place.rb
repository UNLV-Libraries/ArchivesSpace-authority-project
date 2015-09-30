class Place < Sequel::Model(:place)
  include ASModel
  
  corresponds_to JSONModel(:place)
  
  include Publishable
  
  set_model_scope :global

end