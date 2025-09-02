# frozen_string_literal: true
# name: discourse-category-language
# about: Add a language setting to categories
# version: 0.0.1
# authors: EvgeniyKozenok
# url: https://github.com/EvgeniyKozenok/discourse-category-language.git
# required_version: 2.7.0

enabled_site_setting :discourse_category_language_enabled

module ::DiscourseCategoryLanguage
  PLUGIN_NAME = "discourse-category-language"
  DEFAULT_LANGUAGE_ID = 1
end

require_relative "lib/discourse_category_language/engine"


after_initialize do

  require_dependency Rails.root.join("plugins/discourse-category-language/app/models/discourse_category_language/language.rb")

  add_admin_route "admin.title", "discourse-category-language"

end
