class AddWishlistsCountToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :store_products, :wishlists_count, :integer, default: 0, null: false
  end
end
