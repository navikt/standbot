# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:members) do
      add_column :vacation_from, Date
      add_column :vacation_to, Date
    end
  end
end
