Sequel.migration do
  change do
    alter_table(:members) do
      drop_column :slack_im_id
    end
  end
end
