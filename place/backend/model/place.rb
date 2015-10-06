class Place < Sequel::Model(:place)
  include ASModel
  
  corresponds_to JSONModel(:place)
  
  set_model_scope :global

end