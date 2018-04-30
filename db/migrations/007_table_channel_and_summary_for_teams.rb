# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:channels) do
      primary_key :id
      String :name, null: false

      Time :created_at, null: false
      Time :updated_at
    end

    alter_table(:teams) do
      add_column :channel_id, Integer
      add_column :summary, TrueClass
    end
  end
end
