class CreateLineData < ActiveRecord::Migration[5.2]
  def change
    create_table :line_data do |t|
      t.string :symbol
      t.string :period
      t.integer :tid
      t.decimal :open
      t.decimal :close
      t.decimal :high
      t.decimal :low
      t.decimal :vol
      t.decimal :amount
      t.integer :count
    end
  end
end
