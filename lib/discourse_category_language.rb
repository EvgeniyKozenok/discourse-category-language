# frozen_string_literal: true
# lib/discourse_category_language.rb
module ::DiscourseCategoryLanguage
  PLUGIN_NAME = "discourse-category-language"
  DEFAULT_LANGUAGE_ID = 1
end

Dir[File.expand_path("discourse_category_language/**/*.rb", __dir__)].sort.each do |file|
  next if file.include?("/admin/") # exclude admin directory. Loaded by engine with core.
  require_dependency file
end
