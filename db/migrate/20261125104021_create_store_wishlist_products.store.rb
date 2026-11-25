# This migration comes from store (originally 20261125103824)
class CreateStoreWishlistProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :store_wishlist_products do |t|
      t.belongs_to :product, null: false, foreign_key: { to_table: :store_products }
      t.belongs_to :wishlist, null: false, foreign_key: { to_table: :store_wishlists }

      t.timestamps
    end

    add_index :store_wishlist_products, [ :product_id, :wishlist_id ], unique: true
  end
end
