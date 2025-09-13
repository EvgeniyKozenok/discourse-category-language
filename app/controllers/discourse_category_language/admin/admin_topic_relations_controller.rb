# frozen_string_literal: true

module DiscourseCategoryLanguage
  module Admin
    class AdminTopicRelationsController < ::Admin::AdminController
      requires_plugin ::DiscourseCategoryLanguage::PLUGIN_NAME

      # GET /admin/discourse-category-language/topics/:id/alternates
      # Опционально: ?q=search_text
      def alternates
        topic = Topic.find_by(id: params[:id])
        raise Discourse::NotFound unless topic

        category = topic.category
        is_alternates = alternates_mode?(category)
        query = params[:q].to_s.strip

        # Все категории с не-дефолтным языком
        non_default_category_ids = CategoryCustomField
                                     .where(name: "language_id")
                                     .where.not(value: default_language_id.to_s)
                                     .pluck(:category_id)

        # Базовый scope — все топики кроме текущего
        topics_scope = Topic
                         .joins(:category)
                         .where(archetype: Archetype.default)
                         .where.not(id: topic.id)

        # Фильтр по категориям
        if is_alternates
          # мультиселект → только категории с не-дефолтным языком
          topics_scope = topics_scope.where(category_id: non_default_category_ids)
        else
          # одиночный селект → дефолтные или без языка
          topics_scope = topics_scope.where.not(category_id: non_default_category_ids)
        end

        # Поиск по заголовку
        topics_scope = topics_scope.where("title ILIKE ?", "%#{query}%") unless query.empty?

        # Лимит
        topics_scope = topics_scope.limit(50)

        # Форматируем ответ
        formatted = topics_scope.includes(:category).map do |t|
          cat = t.category

          lang_id = category_language_id(cat)
          raw_lang_id = cat.custom_fields["language_id"] # @todo: remove
          lang = DiscourseCategoryLanguage::Language.find_by(id: lang_id)
          lang_slug = lang&.slug

          {
            value: t.id,
            label: "#{t.id}: #{t.title} (#{cat.id}: #{cat.name} [#{lang_id}: #{lang_slug}, #{raw_lang_id.to_i}])",
            disabled: false
          }
        end

        render json: { topics: formatted, is_alternates: is_alternates }
      end

      private

      def default_language_id
        @default_language_id ||= ::DiscourseCategoryLanguage::DEFAULT_LANGUAGE_ID
      end

      def category_language_id(category)
        return default_language_id if category.nil?

        raw = category.custom_fields["language_id"]
        lang_id = raw.to_i
        lang_id > 0 ? lang_id : default_language_id
      end

      def alternates_mode?(category)
        category_language_id(category) == default_language_id
      end
    end
  end
end
