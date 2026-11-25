# This migration comes from store (originally 20261125134400)
class CreateStoreReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :store_reviews do |t|
      t.belongs_to :product, null: false, foreign_key: { to_table: :store_products }
      t.belongs_to :user, null: false, foreign_key: { to_table: :users }
      t.integer :rating, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_column :store_products, :reviews_count, :integer, default: 0, null: false
    add_column :store_products, :rating, :decimal, precision: 2, scale: 1, default: 0
  end
end
