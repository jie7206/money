class CreatePortfolios < ActiveRecord::Migration[5.2]
  def change
    create_table :portfolios do |t|
      t.string :name
      t.string :include_tags
      t.string :exclude_tags
      t.integer :order_num

      t.timestamps
    end
  end
end
