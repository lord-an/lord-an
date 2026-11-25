class AddPriceToStoreProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :store_products, :price_cents, :integer, null: false, default: 0
    add_column :store_products, :currency_code, :string
  end
end
