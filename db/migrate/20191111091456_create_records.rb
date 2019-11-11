class CreateRecords < ActiveRecord::Migration[5.2]
  def change
    create_table :records do |t|
      t.string :class_name
      t.integer :oid
      t.decimal :value

      t.timestamps
    end
  end
end
