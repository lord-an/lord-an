class CreateStoreProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :store_products do |t|
      t.string :name

      t.timestamps
    end
  end
end
