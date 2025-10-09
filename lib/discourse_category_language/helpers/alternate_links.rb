# frozen_string_literal: true
# lib/discourse_category_language/helpers/alternate_links.rb

require_dependency File.expand_path("category_lookup", __dir__)

module ::DiscourseCategoryLanguage::Helpers
  module AlternateLinks
    include ::DiscourseCategoryLanguage::Helpers::CategoryLookup

    # general method for generating html
    def build_alternate_links(mapping)
      return "" if mapping.blank?

      "\n" + mapping.map do |lang, url|
        cleaned_url = url.squeeze('/')
        %Q(<link rel="alternate" hreflang="#{lang}" href="#{cleaned_url}" />)
      end.join("\n")
    end

    # category handler
    def alternates_for_category(category)
      return {} unless category
      build_category_alternates(category)
    end

    # topic handler
    def alternates_for_topic(topic)
      return {} unless topic
      build_topic_alternates(topic)
    end

    # post handler
    def alternates_for_post(post)
      return {} unless post && post.topic
      alternates_for_topic(post.topic)
    end

    def language_slug_for_category(category)
      current = category
      language_id = nil

      while current
        language_id = current.custom_fields&.dig("language_id")
        break if language_id.present?

        current = current.parent_category
      end

      language_id ||= ::DiscourseCategoryLanguage::DEFAULT_LANGUAGE_ID
      lang = ::DiscourseCategoryLanguage::Language.find_by(id: language_id)
      lang&.slug
    end

    private

    def current_base_url
      Discourse.base_url
    end

    # --- topics ---
    def build_topic_alternates(topic)
      return {} unless topic

      mapping = {}

      lang_slug = language_slug_for_category(topic.category)
      mapping[lang_slug] = "#{current_base_url}/t/#{topic.slug}/#{topic.id}" if lang_slug

      alternate_group = topic.custom_fields["alternates"]

      if alternate_group.present?
        Topic
          .joins(:_custom_fields)
          .where(topic_custom_fields: { name: "alternates", value: alternate_group })
          .where.not(id: topic.id)
          .includes(:category)
          .find_each do |alt_topic|
          alt_lang_slug = language_slug_for_category(alt_topic.category)
          mapping[alt_lang_slug] = "#{current_base_url}/t/#{alt_topic.slug}/#{alt_topic.id}" if alt_lang_slug
        end
      end

      prepend_x_default(mapping)
    end


    # --- categories ---
    def build_category_alternates(category)
      return {} unless category

      mapping = {}

      lang_slug = language_slug_for_category(category)
      mapping[lang_slug] = "#{current_base_url}/c/#{category.slug}/#{category.id}" if lang_slug

      alternate_group = category.custom_fields["alternates"]

      if alternate_group.present?
        Category
          .joins(:_custom_fields)
          .where(category_custom_fields: { name: "alternates", value: alternate_group })
          .where.not(id: category.id)
          .includes(:parent_category)
          .find_each do |alt_category|
          alt_lang_slug = language_slug_for_category(alt_category)
          mapping[alt_lang_slug] = "#{current_base_url}/c/#{alt_category.slug}/#{alt_category.id}" if alt_lang_slug
        end
      end

      prepend_x_default(mapping)
    end

    # --- helpers ---
    def prepend_x_default(mapping)
      return mapping if mapping.blank?

      default_lang = ::DiscourseCategoryLanguage::Language.find_by(
        id: ::DiscourseCategoryLanguage::DEFAULT_LANGUAGE_ID
      )&.slug

      if default_lang.present? && mapping.key?(default_lang)
        default_url = mapping[default_lang]
        mapping_without_default = mapping.reject { |k, _| k == default_lang }
        mapping = { "x-default" => default_url, default_lang => default_url }.merge(mapping_without_default)
      end

      mapping
    end

  end
end
