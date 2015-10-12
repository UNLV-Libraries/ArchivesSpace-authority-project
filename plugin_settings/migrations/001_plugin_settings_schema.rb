Sequel.migration do
  up do

    create_table(:plugin_setting) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      String :ead_loc_text, :null => false

      apply_mtime_columns
    end
  end

  down do
    drop_table(:plugin_setting)
  end

end