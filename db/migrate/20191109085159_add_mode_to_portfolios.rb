class AddModeToPortfolios < ActiveRecord::Migration[5.2]
  def change
    add_column :portfolios, :mode, :string
  end
end
