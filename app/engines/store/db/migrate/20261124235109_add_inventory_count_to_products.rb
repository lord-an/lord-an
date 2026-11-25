class AddInventoryCountToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :store_products, :inventory_count, :integer, default: 0
  end
end
