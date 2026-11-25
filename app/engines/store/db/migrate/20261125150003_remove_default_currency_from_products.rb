class RemoveDefaultCurrencyFromProducts < ActiveRecord::Migration[8.1]
  def up
    change_column_default :store_products, :currency_code, nil
    change_column_null :store_products, :currency_code, true
    execute "UPDATE store_products SET currency_code = NULL WHERE price_cents = 0"
  end

  def down
    execute "UPDATE store_products SET currency_code = 'USD' WHERE currency_code IS NULL"
    change_column_null :store_products, :currency_code, false
    change_column_default :store_products, :currency_code, "USD"
  end
end
