# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:teams) do
      add_column :description, String
      add_column :avatar_url, String
    end
  end
end
