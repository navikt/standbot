# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:teams) do
      add_column :standup_time, String
      add_column :reminder, TrueClass
    end
  end
end
