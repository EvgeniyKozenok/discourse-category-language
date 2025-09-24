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
      if match = path.match(%r{^/t/[^/]+/(\d+)(?:/(\d+))?})
        topic_id = match[1].to_i
        post_number = match[2]

        topic = Topic.find_by(id: topic_id)

        if topic
          category = topic.category

          if post_number
            post = topic.posts.find_by(post_number: post_number.to_i)
          end
        end
        # -----------------------
        # Category
        # -----------------------
      elsif match = path.match(%r{^/c/(?:[^/]+/)+(\d+)})
        category_id = match[1].to_i
        category = Category.find_by(id: category_id)
      end

      { post: post, topic: topic, category: category }
    end

    def category_from_request(request)
      discourse_objects_from_request(request)[:category]
    end

    # category slug
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
  end
end
