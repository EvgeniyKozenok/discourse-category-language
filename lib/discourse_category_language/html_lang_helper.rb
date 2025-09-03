module ::DiscourseCategoryLanguage
  module HtmlLangHelper
    def html_lang
      category = nil

      if defined?(request) && request.present?
        path = request.path

        if path =~ %r{^/t/([^/]+)}
          topic_slug = $1
          topic = Topic.find_by(slug: topic_slug) || Topic.find_by(id: topic_slug.to_i)
          category = topic&.category
        elsif path =~ %r{^/c/[^/]+/(\d+)}
          category_id = $1.to_i
          category = Category.find_by(id: category_id)
        end
      end

      if category
        language_id = category.custom_fields["language_id"]
        lang = language_id && DiscourseCategoryLanguage::Language.find_by(id: language_id)
        language_slug = lang&.slug
      else
        default_lang = DiscourseCategoryLanguage::Language.find_by(id: ::DiscourseCategoryLanguage::DEFAULT_LANGUAGE_ID)
        language_slug = default_lang&.slug
      end

      language_slug || "en"
    end
  end
end
