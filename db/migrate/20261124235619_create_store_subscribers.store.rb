# This migration comes from store (originally 20261124235112)
class CreateStoreSubscribers < ActiveRecord::Migration[8.1]
  def change
    create_table :store_subscribers do |t|
      t.belongs_to :product, null: false, foreign_key: { to_table: :store_products }
      t.string :email

      t.timestamps
    end
  end
end
