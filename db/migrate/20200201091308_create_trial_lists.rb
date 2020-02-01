class CreateTrialLists < ActiveRecord::Migration[5.2]
  def change
    create_table :trial_lists do |t|
      t.date :trial_date
      t.decimal :begin_price
      t.decimal :begin_amount
      t.integer :month_cost
      t.decimal :month_sell
      t.integer :begin_balance
      t.integer :begin_balance_twd
      t.decimal :month_grow_rate
      t.decimal :end_price
      t.integer :end_balance
      t.integer :end_balance_twd
    end
  end
end
