class CreateStoreProductTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :store_product_translations do |t|
      t.belongs_to :product, null: false, foreign_key: { to_table: :store_products }
      t.string :locale, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :store_product_translations, [ :product_id, :locale ], unique: true
  end
end
