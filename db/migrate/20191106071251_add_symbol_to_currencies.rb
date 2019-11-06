class AddSymbolToCurrencies < ActiveRecord::Migration[5.2]
  def change
    add_column :currencies, :symbol, :string
  end
end
