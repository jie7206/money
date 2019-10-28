class AddIsHiddenToProperties < ActiveRecord::Migration[5.2]
  def change
    add_column :properties, :is_hidden, :boolean
  end
end
