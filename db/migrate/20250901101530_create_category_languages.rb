# db/migrate/20250901101530_create_category_languages.rb
class CreateCategoryLanguages < ActiveRecord::Migration[6.1]
  def change
    unless table_exists?(:plugin_category_languages)
      create_table :plugin_category_languages do |t|
        t.string :name, null: false
        t.string :slug, null: false
        t.timestamps
      end

      add_index :plugin_category_languages, :slug, unique: true
    end

    reversible do |dir|
      dir.up do
        unless column_exists?(:plugin_category_languages, :id) &&
               execute("SELECT 1 FROM plugin_category_languages WHERE id = 1").any?
          execute <<~SQL
            INSERT INTO plugin_category_languages (id, name, slug, created_at, updated_at)
            VALUES (1, 'English', 'en', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
          SQL
        end
      end
    end
  end
end
