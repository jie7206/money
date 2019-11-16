class AddColumnsToDealRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :deal_records, :account, :string
    add_column :deal_records, :data_id, :integer
  end
end
