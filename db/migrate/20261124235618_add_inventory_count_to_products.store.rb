# This migration comes from store (originally 20261124235109)
class AddInventoryCountToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :store_products, :inventory_count, :integer, default: 0
  end
end
