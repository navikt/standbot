# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:members) do
      drop_column :default_channel_id
      add_column :team_id, Integer
    end
  end
end
