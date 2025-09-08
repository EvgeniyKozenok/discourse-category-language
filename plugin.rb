# frozen_string_literal: true
# name: discourse-category-language
# about: Add a language setting to categories
# version: 0.0.1
# authors: EvgeniyKozenok
# url: https://github.com/EvgeniyKozenok/discourse-category-language.git
# required_version: 2.7.0

enabled_site_setting :discourse_category_language_enabled

require_relative "lib/discourse_category_language"
require_relative "lib/discourse_category_language/engine"

after_initialize do
  # --- models ---
  begin
    require_dependency Rails.root.join("plugins", "discourse-category-language", "app", "models", "discourse_category_language", "language.rb")
  rescue LoadError
    # ignore if not present here (might be loaded by engine)
  end

  add_admin_route "admin.title", "discourse-category-language"

  # --- prepend helper modules throw loader ---
  ::DiscourseCategoryLanguage::HelpersLoader.prepend_helpers

  # --- Ensure SiteController is loaded so we can prepend ---
  require_dependency Rails.root.join("app", "controllers", "site_controller.rb")

  # More robust SiteController patch using prepend (handles base_path)
  ::SiteController.prepend(::DiscourseCategoryLanguage::SiteControllerSkipSkeleton)

  # --- SkipSkeleton for ApplicationController render override (prepend) ---
  ::ApplicationController.prepend ::DiscourseCategoryLanguage::ApplicationControllerSkipSkeleton

  add_to_serializer(:site, :discourse_category_language_default_id) do
    ::DiscourseCategoryLanguage::DEFAULT_LANGUAGE_ID
  end
end
