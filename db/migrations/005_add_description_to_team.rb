# frozen_string_literal: true
Sequel.migration do
  change do
    alter_table(:teams) do
      add_column :description, String
    end
  end
end
