Sequel.migration do

  up do

    create_table(:places) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :accession_id, :null => true

      String :place_role
      String :place_entry
      String :place_source

      apply_mtime_columns
    end


    alter_table(:places) do
      add_foreign_key([:accession_id], :accession, :key => :id)
    end

  end


  down do

    drop_table(:places)

  end

end