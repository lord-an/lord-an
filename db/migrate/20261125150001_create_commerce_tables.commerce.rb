# This migration comes from commerce (originally 20261125150001)
class CreateCommerceTables < ActiveRecord::Migration[8.1]
  def change
    create_table :commerce_carts do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end

    create_table :commerce_cart_items do |t|
      t.references :cart, null: false, foreign_key: { to_table: :commerce_carts }
      t.references :product, null: false, foreign_key: { to_table: :store_products }
      t.integer :quantity, null: false
      t.timestamps
    end
    add_index :commerce_cart_items, [ :cart_id, :product_id ], unique: true

    create_table :commerce_orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending_payment"
      t.string :currency_code, null: false
      t.integer :total_cents, null: false
      t.timestamps
    end

    create_table :commerce_order_items do |t|
      t.references :order, null: false, foreign_key: { to_table: :commerce_orders }
      t.references :product, foreign_key: { to_table: :store_products, on_delete: :nullify }
      t.string :product_name, null: false
      t.integer :quantity, null: false
      t.integer :unit_price_cents, null: false
      t.integer :total_cents, null: false
      t.timestamps
    end
  end
end
