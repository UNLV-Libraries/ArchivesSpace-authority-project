Sequel.migration do
  up do
    alter_table(:extent) do
      add_column(:publish, :integer, :default => '1') 
    end
  end
  down do	
		alter_table(:extent) do
			drop_column(:publish)
		end
	end
end