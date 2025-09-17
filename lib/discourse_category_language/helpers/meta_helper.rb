# frozen_string_literal: true
# lib/discourse_category_language/helpers/meta_helper.rb
module ::DiscourseCategoryLanguage::Helpers
  module MetaHelper
    include ::DiscourseCategoryLanguage::Helpers::CategoryLookup
    include ::DiscourseCategoryLanguage::Helpers::AlternateLinks

    def crawlable_meta_data(opts = nil)
      opts ||= {}
      objects = discourse_objects_from_request(request)

      if objects[:category]
        language_id = objects[:category].custom_fields["language_id"]
        lang = DiscourseCategoryLanguage::Language.find_by(id: language_id)
        opts[:meta_language] = lang.slug if lang
      end

      html = super(opts)

      #html += %Q(<meta name="language" content="#{opts[:meta_language]}">) if opts[:meta_language]

      meta_object =
        if objects[:post]
          { name: "post", id: objects[:post].id }
        elsif objects[:topic]
          { name: "topic", id: objects[:topic].id }
        elsif objects[:category]
          { name: "category", id: objects[:category].id }
        end

      if meta_object
        #html += %Q(<meta name="#{meta_object[:name]}" content="#{meta_object[:id]}">)
      end

      alternates =
        if objects[:post]
          alternates_for_post(objects[:post])
        elsif objects[:topic]
          alternates_for_topic(objects[:topic])
        elsif objects[:category]
          alternates_for_category(objects[:category])
        else
          {}
        end

      html + build_alternate_links(alternates).html_safe
    end
  end
end
