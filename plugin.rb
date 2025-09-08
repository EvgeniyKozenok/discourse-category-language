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
  # --- models ---
  begin
    require_dependency Rails.root.join("plugins", "discourse-category-language", "app", "models", "discourse_category_language", "language.rb")
  rescue LoadError
    # ignore if not present here (might be loaded by engine)
  end

  # --- try to load helpers / modules from plugin (if they exist) ---
  [
    "lib/discourse_category_language/html_lang_helper.rb",
    #"lib/discourse_category_language/meta_helper.rb",
    #"lib/discourse_category_language/category_lookup.rb",
    #"lib/discourse_category_language/alternate_links.rb"
  ].each do |rel|
    path = File.expand_path(rel, __dir__)
    begin
      require_dependency path if File.exist?(path)
    rescue => e
      Rails.logger.warn("discourse-category-language: failed to require #{path}: #{e}")
    end
  end

  # Prepend helper modules if they are defined (safe guard)
  if defined?(::DiscourseCategoryLanguage::HtmlLangHelper)
    ::ApplicationHelper.prepend ::DiscourseCategoryLanguage::HtmlLangHelper
  end

  if defined?(::DiscourseCategoryLanguage::MetaHelper)
    ::ApplicationHelper.prepend ::DiscourseCategoryLanguage::MetaHelper
  end

  if defined?(::DiscourseCategoryLanguage::CategoryLookup)
    ::ApplicationHelper.prepend ::DiscourseCategoryLanguage::CategoryLookup
  end

  if defined?(::DiscourseCategoryLanguage::AlternateLinks)
    ::ApplicationHelper.prepend ::DiscourseCategoryLanguage::AlternateLinks
  end

  # --- Ensure SiteController is loaded so we can prepend ---
  require_dependency Rails.root.join("app", "controllers", "site_controller.rb")

  # More robust SiteController patch using prepend (handles base_path)
  module ::DiscourseCategoryLanguage
    module SiteControllerSkipSkeleton
      def site
        path = request.path.to_s
        base = Discourse.base_path.to_s
        # normalize base: if "/" treat as empty string for matching
        base = "" if base == "/"

        # match both /t/ and /c/ with base_path taken into account
        if params[:disable_skeleton] || path.match?(%r{\A#{Regexp.escape(base)}/(t|c)/})
          @skip_precompiled = true
          Rails.logger.info("discourse-category-language: skip_precompiled=true for #{path}")
        end

        super
      end
    end
  end

  ::SiteController.prepend ::DiscourseCategoryLanguage::SiteControllerSkipSkeleton

  # --- SkipSkeleton for ApplicationController render override (prepend) ---
  module ::DiscourseCategoryLanguage
    module SkipSkeleton
      # Use kwargs-friendly signature for modern Ruby
      def render(*args, **kwargs, &block)
        if defined?(@skip_precompiled) && @skip_precompiled
          # Force rendering the full layout template if not already set
          kwargs[:template] ||= "layouts/application"
        end
        super(*args, **kwargs, &block)
      end
    end
  end

  ::ApplicationController.prepend ::DiscourseCategoryLanguage::SkipSkeleton
end
