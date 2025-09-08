# lib/discourse_category_language/helpers/html_lang_helper.rb

module ::DiscourseCategoryLanguage::Helpers
  module HtmlLangHelper
    include ::DiscourseCategoryLanguage::Helpers::CategoryLookup

    def html_lang
      category = category_from_request(request)

      if category
        language_id = category.custom_fields["language_id"]
        lang = language_id && DiscourseCategoryLanguage::Language.find_by(id: language_id)
        language_slug = lang&.slug
      else
        default_lang = DiscourseCategoryLanguage::Language.find_by(id: ::DiscourseCategoryLanguage::DEFAULT_LANGUAGE_ID)
        language_slug = default_lang&.slug
      end

      language_slug || super
    end
  end
end
