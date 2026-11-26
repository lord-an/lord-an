class AddAvataxTaxCodeToCommerceOrderItems < ActiveRecord::Migration[8.1]
  def change
    add_column :commerce_order_items, :avatax_tax_code, :string
  end
end
