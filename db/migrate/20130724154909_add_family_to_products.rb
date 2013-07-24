class AddFamilyToProducts < ActiveRecord::Migration
  def change
    add_column :products, :family_id, :integer
    add_index :products, :family_id
  end
end
