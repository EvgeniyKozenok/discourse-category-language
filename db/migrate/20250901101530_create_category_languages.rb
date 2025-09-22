# frozen_string_literal: true
# db/migrate/20250901101530_create_category_languages.rb

class CreateCategoryLanguages < ActiveRecord::Migration[6.1]
  def up
    # create a language table if it doesn't exist
    unless table_exists?(:plugin_category_languages)
      create_table :plugin_category_languages do |t|
        t.string :name, null: false
        t.string :slug, null: false
        t.timestamps
      end

      add_index :plugin_category_languages, :slug, unique: true
    end

    # list of languages with fixed ids
    languages = {
      1  => ["English", "en"],
      2  => ["Svenska", "se"],
      3  => ["Brazilian/Portuguese", "pt-br"],
      4  => ["Dutch", "nl"],
      5  => ["Korean", "ko"],
      6  => ["Turkish", "tr"],
      7  => ["Polish", "pl"],
      8  => ["Norwegian", "no"],
      9  => ["Japanese", "jp"],
      10 => ["Italian", "it"],
      11 => ["German", "de"],
      12 => ["Spanish", "es"],
      13 => ["French", "fr"],
      14 => ["Chinese", "cn"]
    }

    # insert languages
    languages.each do |id, (name, slug)|
      execute <<~SQL
        INSERT INTO plugin_category_languages (id, name, slug, created_at, updated_at)
        VALUES (#{id}, #{ActiveRecord::Base.connection.quote(name)}, #{ActiveRecord::Base.connection.quote(slug)}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ON CONFLICT (id) DO NOTHING
      SQL
    end

    # synchronize the sequence with the maximum id
    execute <<~SQL
      SELECT setval('plugin_category_languages_id_seq', (SELECT COALESCE(MAX(id), 1) FROM plugin_category_languages));
    SQL

    # mapping: category -> languages
    category_mapping = {
      "swedish-forum"               => "se",
      "brazilian-portuguese-forum"  => "pt-br",
      "dutch-forum"                 => "nl",
      "korean-forum"                => "ko",
      "turkish-forum"               => "tr",
      "polish-forum"                => "pl",
      "norwegian-forum"             => "no",
      "japanese-forum"              => "jp",
      "italian-forum"               => "it",
      "german-forum"                => "de",
      "spanish-forum"               => "es",
      "french-forum"                => "fr",
      "chinese-forum"               => "cn"
    }

    category_mapping.each do |cat_slug, lang_slug|
      lang_id_row = execute("SELECT id FROM plugin_category_languages WHERE slug = #{ActiveRecord::Base.connection.quote(lang_slug)}").first
      next unless lang_id_row
      lang_id = lang_id_row["id"]

      cat_id_row = execute("SELECT id FROM categories WHERE slug = #{ActiveRecord::Base.connection.quote(cat_slug)} AND parent_category_id IS NULL").first
      next unless cat_id_row
      cat_id = cat_id_row["id"]

      # safely delete the old value and insert the new one
      execute <<~SQL
        DELETE FROM category_custom_fields
        WHERE category_id = #{cat_id} AND name = 'language_id';
      SQL

      execute <<~SQL
        INSERT INTO category_custom_fields (category_id, name, value, created_at, updated_at)
        VALUES (#{cat_id}, 'language_id', #{lang_id}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
      SQL
    end
  end

  def down
    # remove all language_id from custom fields
    execute "DELETE FROM category_custom_fields WHERE name = 'language_id'"

    # delete the language table
    drop_table :plugin_category_languages, if_exists: true
  end
end
