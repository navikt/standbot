# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:teams) do
      drop_column :channel_id
      drop_column :description
    end

    drop_table(:channels)
  end
end
