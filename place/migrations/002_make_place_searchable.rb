Sequel.migration do

  up do
    [:agent_person, :agent_software, :agent_corporate_entity,
     :agent_family].each do |table|
      self[table].update(:system_mtime => Time.now)
    end
  end

end
