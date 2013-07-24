class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.float :price
      t.float :tva
      t.text :description
      t.boolean :visible

      t.timestamps
    end
  end
end
