class CreateDealRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :deal_records do |t|
      t.string :type
      t.string :symbol
      t.decimal :price
      t.decimal :amount
      t.decimal :fees
      t.string :purpose
      t.integer :loss_limit
      t.integer :earn_limit
      t.boolean :auto_deal

      t.timestamps
    end
  end
end
