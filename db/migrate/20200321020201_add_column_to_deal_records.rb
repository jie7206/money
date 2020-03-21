class AddColumnToDealRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :deal_records, :first_sell, :boolean
  end
end
