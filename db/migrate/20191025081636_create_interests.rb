class CreateInterests < ActiveRecord::Migration[5.2]
  def change
    create_table :interests do |t|
      t.references :property, foreign_key: true
      t.date :start_date
      t.decimal :rate

      t.timestamps
    end
  end
end
