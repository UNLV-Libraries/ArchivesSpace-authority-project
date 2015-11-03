class AgentPlace < Sequel::Model(:agent_place)
  include ASModel
  
  corresponds_to JSONModel(:agent_place)
  
  set_model_scope :global

end