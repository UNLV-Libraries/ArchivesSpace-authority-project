class Places < Sequel::Model(:places)
  include ASModel
  corresponds_to JSONModel(:places)

  set_model_scope :global

end