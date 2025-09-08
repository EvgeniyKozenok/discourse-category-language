# lib/discourse_category_language/helpers/alternate_links.rb

require_dependency File.expand_path("category_lookup", __dir__)

module ::DiscourseCategoryLanguage::Helpers
  module AlternateLinks
    include ::DiscourseCategoryLanguage::Helpers::CategoryLookup

    # general method for generating html
    def build_alternate_links(mapping)
      mapping.map do |lang, url|
        %Q(<link rel="alternate" hreflang="#{lang}" href="#{url}" />)
      end.join("\n")
    end

    # category handler
    def alternates_for_category(category)
      return {} unless category

      # if there is x_defaults, use the category with this ID
      if category.custom_fields["x_defaults"].present?
        category_id = category.custom_fields["x_defaults"].to_i
        category = Category.find_by(id: category_id)
        return {} unless category
      end

      alternate_ids = category.custom_fields["alternates"]
      build_category_alternates(category, alternate_ids)
    end

    # topic handler
    def alternates_for_topic(topic)
      return {} unless topic

      if topic.custom_fields["x_defaults"].present?
        topic_id = topic.custom_fields["x_defaults"].to_i
        topic = Topic.find_by(id: topic_id)
        return {} unless topic
      end

      alternate_ids = topic.custom_fields["alternates"]
      build_topic_alternates(topic, alternate_ids)
    end

    # post handler (if we decide to support it)
    def alternates_for_post(post)
      {}
    end

    private

    def current_base_url
      Discourse.base_url
    end

    # --- topics ---
    def build_topic_alternates(topic, alternate_ids)
      return {} if topic.nil?

      mapping = {}
      x_default_url = "#{current_base_url}/t/#{topic.slug}/#{topic.id}"
      mapping["x-default"] = x_default_url

      # key with the language of the category of the current topic
      lang_slug = language_slug_for_category(topic.category)
      mapping[lang_slug] = x_default_url if lang_slug

      return mapping if alternate_ids.blank?

      ids = Array(alternate_ids).map(&:to_i)
      Topic.where(id: ids).includes(:category).find_each do |alt_topic|
        alt_lang_slug = language_slug_for_category(alt_topic.category)
        mapping[alt_lang_slug] = "#{current_base_url}/t/#{alt_topic.slug}/#{alt_topic.id}" if alt_lang_slug
      end

      mapping
    end

    # --- categories ---
    def build_category_alternates(category, alternate_ids)
      return {} if category.nil?

      mapping = {}
      x_default_url = "#{current_base_url}/c/#{category.slug}/#{category.id}"
      mapping["x-default"] = x_default_url

      # key with category language
      lang_slug = language_slug_for_category(category)
      mapping[lang_slug] = x_default_url if lang_slug

      return mapping if alternate_ids.blank?

      ids = Array(alternate_ids).map(&:to_i)
      Category.where(id: ids).find_each do |alt_category|
        alt_lang_slug = language_slug_for_category(alt_category)
        mapping[alt_lang_slug] = "#{current_base_url}/c/#{alt_category.slug}/#{alt_category.id}" if alt_lang_slug
      end

      mapping
    end

  end
end
