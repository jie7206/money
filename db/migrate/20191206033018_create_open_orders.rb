class CreateOpenOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :open_orders do |t|
      t.string :order_id
      t.string :symbol
      t.decimal :amount
      t.decimal :price
      t.string :order_type

      t.timestamps
    end
  end
end
