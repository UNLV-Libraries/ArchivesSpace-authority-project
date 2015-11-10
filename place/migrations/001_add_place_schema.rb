Sequel.migration do
  up do

    create_table(:place) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :agent_person_id, :null => true
      Integer :agent_family_id, :null => true
      Integer :agent_corporate_entity_id, :null => true
      Integer :agent_software_id, :null => true
	  Integer :accession_id, :null => true
      Integer :resource_id, :null => true
      Integer :digital_object_id, :null => true

      String :role, :null => false

      apply_mtime_columns
    end


    alter_table(:place) do
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
    end

  end

  down do
    drop_table(:place)
  end

end