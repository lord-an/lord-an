class AddStoreProductAvataxTaxCode < ActiveRecord::Migration[8.1]
  def change
    add_column :store_products, :avatax_tax_code, :string
  end
end
