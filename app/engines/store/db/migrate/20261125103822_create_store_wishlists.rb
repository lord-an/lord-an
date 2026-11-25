class CreateStoreWishlists < ActiveRecord::Migration[8.1]
  def change
    create_table :store_wishlists do |t|
      t.belongs_to :user, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.integer :products_count, default: 0, null: false

      t.timestamps
    end
  end
end
