# frozen_string_literal: true

module DiscourseCategoryLanguage
  class PublicCategoryLanguageController < ::ApplicationController
    requires_plugin ::DiscourseCategoryLanguage::PLUGIN_NAME
    requires_login false

    helper ::DiscourseCategoryLanguage::Helpers::AlternateLinks

    # GET /discourse-category-language/spa-meta/:id/:entity
    def spa_meta
      entity_type = params[:entity]
      entity_id = params[:id]

      default_language = DiscourseCategoryLanguage::Language.find(::DiscourseCategoryLanguage::DEFAULT_LANGUAGE_ID)
      default_slug = default_language.slug

      case entity_type
      when "topic"
        topic = Topic.find_by(id: entity_id)
        if topic
          category = topic.category
          alternates = helpers.alternates_for_topic(topic)
          lang_slug = helpers.language_slug_for_category(category)
        else
          render json: { error: "Topic not found" }, status: 404
          return
        end
      when "category"
        category = Category.find_by(id: entity_id)
        if category
          alternates = helpers.alternates_for_category(category)
          lang_slug = helpers.language_slug_for_category(category)
        else
          render json: { error: "Category not found" }, status: 404
          return
        end
      else
        render json: { error: "Unknown type" }, status: 400
        return
      end

      render json: {
        slug: lang_slug,
        default_slug: default_slug,
        alternates: alternates
      }
    end
  end
end

