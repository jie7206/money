class AddColumnsToPortfolios < ActiveRecord::Migration[5.2]
  def change
    add_column :portfolios, :twd_amount, :integer
    add_column :portfolios, :cny_amount, :integer
    add_column :portfolios, :proportion, :decimal
  end
end
