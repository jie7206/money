class AddTwoColumnsToDealRecords < ActiveRecord::Migration[5.2]
  def change
    add_column :deal_records, :order_id, :string
    add_column :deal_records, :real_profit, :decimal
  end
end
