# frozen_string_literal: true
# lib/discourse_category_language/helpers/category_lookup.rb
module ::DiscourseCategoryLanguage::Helpers
  module CategoryLookup
    def discourse_objects_from_request(request)
      return { post: nil, topic: nil, category: nil } unless request&.path

      path = request.path
      post = topic = category = nil

      # -----------------------
      # Topic or Post
      # -----------------------
      if path =~ %r{^/t/([^/]+)(?:/(\d+))?}
        topic_slug = $1
        post_number = $2

        topic = Topic.find_by(slug: topic_slug) || Topic.find_by(id: topic_slug.to_i)

        if topic
          category = topic.category

          if post_number
            post = topic.posts.find_by(post_number: post_number.to_i)
          end
        end
        # -----------------------
        # Category
        # -----------------------
      elsif path =~ %r{^/c/[^/]+/(\d+)}
        category = Category.find_by(id: $1.to_i)
      end

      { post: post, topic: topic, category: category }
    end

    def category_from_request(request)
      discourse_objects_from_request(request)[:category]
    end

    # category slug
    def language_slug_for_category(category)
      language_id = category&.custom_fields&.dig("language_id") || ::DiscourseCategoryLanguage::DEFAULT_LANGUAGE_ID
      lang = ::DiscourseCategoryLanguage::Language.find_by(id: language_id)
      lang&.slug
    end
  end
end
