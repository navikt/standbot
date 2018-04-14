# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:standups) do
      primary_key :id
      String :slackid, null: false
      String :name, null: false
      String :yesterday
      String :today
      String :problems
      Time :created_at, null: false
      Time :updated_at
    end
  end

  down do
    drop_table(:standups)
  end
end
