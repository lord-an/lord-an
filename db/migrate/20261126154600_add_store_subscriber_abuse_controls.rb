class AddStoreSubscriberAbuseControls < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      DELETE FROM store_subscribers
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM store_subscribers
        GROUP BY product_id, LOWER(email)
      )
    SQL

    add_column :store_subscribers, :confirmed_at, :datetime
    add_column :store_subscribers, :confirmation_sent_at, :datetime
    add_index :store_subscribers, [ :product_id, :email ], unique: true,
      name: "index_store_subscribers_on_product_and_email"
  end

  def down
    remove_index :store_subscribers, name: "index_store_subscribers_on_product_and_email"
    remove_column :store_subscribers, :confirmation_sent_at
    remove_column :store_subscribers, :confirmed_at
  end
end
