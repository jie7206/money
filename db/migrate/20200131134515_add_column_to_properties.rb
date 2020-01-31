class AddColumnToProperties < ActiveRecord::Migration[5.2]
  def change
    add_column :properties, :is_locked, :boolean
  end
end
