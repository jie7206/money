class AddReferencesToProperties < ActiveRecord::Migration[5.2]
  def change
    add_reference :properties, :currency, foreign_key: true
  end
end
