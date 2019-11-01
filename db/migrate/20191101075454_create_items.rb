class CreateItems < ActiveRecord::Migration[5.2]
  def change
    create_table :items do |t|
      t.references :property, foreign_key: true
      t.decimal :price
      t.decimal :amount
      t.string :url

      t.timestamps
    end
  end
end
