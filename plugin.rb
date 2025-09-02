# frozen_string_literal: true

# frozen_string_literal: true
# name: discourse-category-language
# about: Add a language setting to categories
# version: 0.0.1
# authors: john
# url: https://github.com/your-username/discourse-category-language
# required_version: 2.7.0

enabled_site_setting :discourse_category_language_enabled

module ::DiscourseCategoryLanguage
  PLUGIN_NAME = "discourse-category-language"
end

require_relative "lib/discourse_category_language/engine"


after_initialize do

  add_admin_route "admin.title", "discourse-category-language"

end
