class CreateLunaStyleThemeSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :luna_style_theme_settings do |t|
      t.string :key, null: false
      t.string :theme, null: false, default: "classic"

      t.timestamps
      t.index :key, unique: true
    end
  end
end
