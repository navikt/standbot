# frozen_string_literal: true
Sequel.migration do
  up do
    drop_table(:standups)

    create_table(:members) do
      primary_key :id
      String :slack_id, null: false
      String :slack_im_id, null: false
      String :full_name, null: false
      String :default_channel_id
      String :avatar_url

      Time :created_at, null: false
      Time :updated_at
    end

    create_table(:reports) do
      primary_key :id
      Int :member_id
      Int :standup_id
      String :yesterday
      String :today
      String :problem

      Time :created_at, null: false
      Time :updated_at
    end

    create_table(:standups) do
      primary_key :id
      Int :team_id

      Time :created_at, null: false
      Time :updated_at
    end

    create_table(:channels) do
      primary_key :id
      String :name, null: false

      Time :created_at, null: false
      Time :updated_at
    end

    create_table(:memberships) do
      primary_key :id
      Int :team_id, null: false
      int :member_id, null: false

      Time :created_at
      Time :updated_at
    end

    create_table(:teams) do
      primary_key :id
      String :name, null: false
      Int :channel_id
      Bool :active, default: true

      Time :created_at, null: false
      Time :updated_at
    end
  end

  down do
    drop_table(:channels)
    drop_table(:members)
    drop_table(:reports)
    drop_table(:standups)
    drop_table(:teams)
    drop_table(:memberships)

    create_table(:standups) do
      primary_key :id
      String :slackid, null: false
      String :name, null: false
      String :yesterday
      String :today
      String :problems
      String :avatar_url

      Time :created_at, null: false
      Time :updated_at
    end
  end
end
