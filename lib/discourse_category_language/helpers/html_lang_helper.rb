# frozen_string_literal: true
# lib/discourse_category_language/helpers/html_lang_helper.rb

module ::DiscourseCategoryLanguage::Helpers
  module HtmlLangHelper
    include ::DiscourseCategoryLanguage::Helpers::CategoryLookup

    def html_lang
      category = category_from_request(request)

      if category
        language_slug = language_slug_for_category(category)
      end

      language_slug || super
    end
  end
end
