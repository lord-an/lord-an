# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_26_164200) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "commerce_cart_items", force: :cascade do |t|
    t.integer "cart_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_id"], name: "index_commerce_cart_items_on_cart_id_and_product_id", unique: true
    t.index ["cart_id"], name: "index_commerce_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_commerce_cart_items_on_product_id"
  end

  create_table "commerce_carts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "checkout_order_id"
    t.index ["checkout_order_id"], name: "index_commerce_carts_on_checkout_order_id"
    t.index ["user_id"], name: "index_commerce_carts_on_user_id", unique: true
  end

  create_table "commerce_order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "product_id"
    t.string "product_name", null: false
    t.integer "quantity", null: false
    t.integer "unit_price_cents", null: false
    t.integer "total_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "shipping_weight_grams"
    t.string "avatax_tax_code"
    t.index ["order_id"], name: "index_commerce_order_items_on_order_id"
    t.index ["product_id"], name: "index_commerce_order_items_on_product_id"
  end

  create_table "commerce_orders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "status", default: "pending_payment", null: false
    t.string "currency_code", null: false
    t.integer "total_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "merchant_reference"
    t.integer "tax_cents", default: 0, null: false
    t.integer "shipping_cents", default: 0, null: false
    t.string "shipping_name"
    t.string "shipping_line1"
    t.string "shipping_line2"
    t.string "shipping_city"
    t.string "shipping_region"
    t.string "shipping_postal_code"
    t.string "shipping_country_code"
    t.string "adyen_session_id"
    t.text "adyen_checkout_url"
    t.string "payment_psp_reference"
    t.string "tax_transaction_code"
    t.datetime "expires_at"
    t.datetime "tax_committed_at"
    t.datetime "fulfilled_at"
    t.datetime "tax_voided_at"
    t.index ["adyen_session_id"], name: "index_commerce_orders_on_adyen_session_id", unique: true
    t.index ["merchant_reference"], name: "index_commerce_orders_on_merchant_reference", unique: true
    t.index ["tax_transaction_code"], name: "index_commerce_orders_on_tax_transaction_code", unique: true
    t.index ["user_id"], name: "index_commerce_orders_on_user_id"
  end

  create_table "luna_style_theme_settings", force: :cascade do |t|
    t.string "key", null: false
    t.string "theme", default: "classic", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_luna_style_theme_settings_on_key", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "store_product_translations", force: :cascade do |t|
    t.integer "product_id", null: false
    t.string "locale", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "locale"], name: "index_store_product_translations_on_product_id_and_locale", unique: true
    t.index ["product_id"], name: "index_store_product_translations_on_product_id"
  end

  create_table "store_products", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "inventory_count", default: 0
    t.integer "wishlists_count", default: 0, null: false
    t.integer "reviews_count", default: 0, null: false
    t.decimal "rating", precision: 2, scale: 1, default: "0.0"
    t.integer "price_cents", default: 0, null: false
    t.string "currency_code"
    t.integer "shipping_weight_grams"
    t.string "avatax_tax_code"
  end

  create_table "store_reviews", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "user_id", null: false
    t.integer "rating", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_store_reviews_on_product_id"
    t.index ["user_id"], name: "index_store_reviews_on_user_id"
  end

  create_table "store_sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_store_sessions_on_user_id"
  end

  create_table "store_subscribers", force: :cascade do |t|
    t.integer "product_id", null: false
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.index ["product_id", "email"], name: "index_store_subscribers_on_product_and_email", unique: true
    t.index ["product_id"], name: "index_store_subscribers_on_product_id"
  end

  create_table "store_users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_store_users_on_email_address", unique: true
  end

  create_table "store_wishlist_products", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "wishlist_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "wishlist_id"], name: "index_store_wishlist_products_on_product_id_and_wishlist_id", unique: true
    t.index ["product_id"], name: "index_store_wishlist_products_on_product_id"
    t.index ["wishlist_id"], name: "index_store_wishlist_products_on_wishlist_id"
  end

  create_table "store_wishlists", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.integer "products_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_store_wishlists_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "preferred_locale", default: "en", null: false
    t.boolean "admin", default: false, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "commerce_cart_items", "commerce_carts", column: "cart_id"
  add_foreign_key "commerce_cart_items", "store_products", column: "product_id", on_delete: :cascade
  add_foreign_key "commerce_carts", "commerce_orders", column: "checkout_order_id"
  add_foreign_key "commerce_carts", "users"
  add_foreign_key "commerce_order_items", "commerce_orders", column: "order_id"
  add_foreign_key "commerce_order_items", "store_products", column: "product_id", on_delete: :nullify
  add_foreign_key "commerce_orders", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "store_product_translations", "store_products", column: "product_id"
  add_foreign_key "store_reviews", "store_products", column: "product_id"
  add_foreign_key "store_reviews", "users"
  add_foreign_key "store_sessions", "store_users", column: "user_id"
  add_foreign_key "store_subscribers", "store_products", column: "product_id"
  add_foreign_key "store_wishlist_products", "store_products", column: "product_id"
  add_foreign_key "store_wishlist_products", "store_wishlists", column: "wishlist_id"
  add_foreign_key "store_wishlists", "users"
end
