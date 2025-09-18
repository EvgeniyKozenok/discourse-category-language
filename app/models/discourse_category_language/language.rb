# frozen_string_literal: true

module DiscourseCategoryLanguage
  class Language < ActiveRecord::Base
    self.table_name = "plugin_category_languages"

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: true
  end
end

# == Schema Information
#
# Table name: plugin_category_languages
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_plugin_category_languages_on_slug  (slug) UNIQUE
#
