class AddCheckoutCommerceFields < ActiveRecord::Migration[8.1]
  def change
    add_column :store_products, :shipping_weight_grams, :integer

    add_column :commerce_carts, :checkout_order_id, :integer
    add_index :commerce_carts, :checkout_order_id
    add_foreign_key :commerce_carts, :commerce_orders, column: :checkout_order_id

    add_column :commerce_orders, :merchant_reference, :string
    add_column :commerce_orders, :tax_cents, :integer, null: false, default: 0
    add_column :commerce_orders, :shipping_cents, :integer, null: false, default: 0
    add_column :commerce_orders, :shipping_name, :string
    add_column :commerce_orders, :shipping_line1, :string
    add_column :commerce_orders, :shipping_line2, :string
    add_column :commerce_orders, :shipping_city, :string
    add_column :commerce_orders, :shipping_region, :string
    add_column :commerce_orders, :shipping_postal_code, :string
    add_column :commerce_orders, :shipping_country_code, :string
    add_column :commerce_orders, :adyen_session_id, :string
    add_column :commerce_orders, :adyen_checkout_url, :text
    add_column :commerce_orders, :payment_psp_reference, :string
    add_column :commerce_orders, :tax_transaction_code, :string
    add_column :commerce_orders, :expires_at, :datetime
    add_column :commerce_orders, :tax_committed_at, :datetime
    add_index :commerce_orders, :merchant_reference, unique: true
    add_index :commerce_orders, :adyen_session_id, unique: true
    add_index :commerce_orders, :tax_transaction_code, unique: true

    add_column :commerce_order_items, :shipping_weight_grams, :integer
  end
end
