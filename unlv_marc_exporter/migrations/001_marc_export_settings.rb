Sequel.migration do
  up do

    create_table(:marc_export_settings) do
	  primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :repo_id, :null => false
      Integer :marc_export_user_id, :null => true
      String :user_uniq, :null => false

      MediumBlobField :m_export_settings, :null => false

      apply_mtime_columns
    end
  
    alter_table(:marc_export_settings) do
      add_foreign_key([:repo_id], :repository, :key => :id)
      add_foreign_key([:marc_export_user_id], :user, :key => :id)
      add_unique_constraint([:repo_id, :user_uniq], :name => "marc_export_settings_uniq")
	end

  end
  down do
    drop_table(:marc_export_settings)
  end

end