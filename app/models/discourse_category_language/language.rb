# frozen_string_literal: true

module DiscourseCategoryLanguage
  class Language < ActiveRecord::Base
    self.table_name = "plugin_category_languages"

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: true
  end
end
