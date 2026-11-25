class CascadeProductDeletionsToCartItems < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :commerce_cart_items, column: :product_id
    add_foreign_key :commerce_cart_items, :store_products, column: :product_id, on_delete: :cascade
  end
end
