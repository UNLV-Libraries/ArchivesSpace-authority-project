Sequel.migration do
  up do

    create_table(:spawn_settings) do
	  primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false
      Integer :spawn_user_id, :null => true
      String :user_uniq, :null => false

      MediumBlobField :spawn_defaults, :null => false

      apply_mtime_columns
    end
  
    alter_table(:spawn_settings) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_foreign_key([:spawn_user_id], :user, :key => :id)
      add_unique_constraint([:repo_id, :user_uniq], :name => "spawn_settings_uniq")
	end

  end
  down do
    drop_table(:spawn_settings)
  end

end