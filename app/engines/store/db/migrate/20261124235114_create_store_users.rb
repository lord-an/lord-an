class CreateStoreUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :store_users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false

      t.timestamps
    end
    add_index :store_users, :email_address, unique: true
  end
end
