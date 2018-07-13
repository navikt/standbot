# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:standup_days) do
      primary_key :id
      Integer :team_id, null: false
      String :name, null: false

      Time :created_at, null: false
      Time :updated_at
    end
  end
end
