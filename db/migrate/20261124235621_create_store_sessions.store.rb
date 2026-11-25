# This migration comes from store (originally 20261124235117)
class CreateStoreSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :store_sessions do |t|
      t.references :user, null: false, foreign_key: { to_table: :store_users }
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
