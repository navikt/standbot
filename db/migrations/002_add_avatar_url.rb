Sequel.migration do
  change do
    alter_table(:standups) do
      add_column :avatar_url, String
    end
  end
end
