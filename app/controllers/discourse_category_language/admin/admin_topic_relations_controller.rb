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
          topics_scope = topics_scope.where(category_id: non_default_category_ids)
        else
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
          lang = DiscourseCategoryLanguage::Language.find_by(id: lang_id)
          {
            value: t.id,
            label: "#{t.id}: #{t.title} (#{cat.id}: #{cat.name} [#{lang_id}: #{lang&.slug}])",
            disabled: false
          }
        end

        # Определяем текущие выбранные топики
        if is_alternates
          selected_topics = Array(topic.custom_fields["alternates"]).map(&:to_i)
          selected_topic = nil
        else
          selected_topics = []
          selected_topic = topic.custom_fields["x_defaults"]&.to_i
        end

        # Добавляем выбранные топики в массив доступных топиков, если их нет
        formatted = ensure_selected_included(formatted, selected_topics + [selected_topic].compact)

        render json: {
          topics: formatted,
          is_alternates: is_alternates,
          selected_topics: selected_topics,
          selected_topic: selected_topic
        }
      end

      # PATCH /admin/discourse-category-language/topics/:id/alternates_update
      def alternates_update
        topic = Topic.find_by(id: params[:id])
        raise Discourse::NotFound unless topic

        new_alternates = Array(params[:alternates]).map(&:to_i)

        ActiveRecord::Base.transaction do
          # 1️⃣ Сохраняем массив альтернатив в текущем топике
          topic.custom_fields["alternates"] = new_alternates
          topic.save_custom_fields
          Rails.logger.info("Updated topic #{topic.id} alternates: #{new_alternates.inspect}")

          # 2️⃣ Проставляем x_defaults для выбранных альтернатив
          Topic.where(id: new_alternates).find_each do |alt_topic|
            alt_topic.custom_fields["x_defaults"] = topic.id
            alt_topic.save_custom_fields
            Rails.logger.info("Set x_defaults for topic #{alt_topic.id} -> #{topic.id}")
          end

          # 3️⃣ Удаляем x_defaults для топиков, которые раньше были альтами, а сейчас нет
          Topic.all.each do |other_topic|
            next if new_alternates.include?(other_topic.id)
            if other_topic.custom_fields["x_defaults"].to_i == topic.id
              other_topic.custom_fields.delete("x_defaults")
              other_topic.save_custom_fields
              Rails.logger.info("Removed x_defaults for topic #{other_topic.id}")
            end
          end

          # 4️⃣ Убираем текущие альтернативы из чужих массивов alternates
          Topic.where.not(id: topic.id).find_each do |other_topic|
            alt_array = Array(other_topic.custom_fields["alternates"]).map(&:to_i)
            updated = false

            new_alternates.each do |alt_id|
              if alt_array.include?(alt_id)
                alt_array.delete(alt_id)
                updated = true
              end
            end

            if updated
              other_topic.custom_fields["alternates"] = alt_array
              other_topic.save_custom_fields
              Rails.logger.info("Cleaned alternates for topic #{other_topic.id}, removed: #{new_alternates.inspect}")
            end
          end
        end

        # 5️⃣ Возвращаем фронту готовый JSON через метод alternates
        alternates
      end

      # PATCH /admin/discourse-category-language/topics/:id/:x_default/assign_default
      # Для одиночного селекта (isAlternates === false)
      def assign_default
        topic = Topic.find_by(id: params[:id])
        raise Discourse::NotFound unless topic

        parent_id = params[:x_default].to_i > 0 ? params[:x_default].to_i : nil

        ActiveRecord::Base.transaction do
          topic.custom_fields["x_defaults"] = parent_id
          topic.save_custom_fields

          if parent_id
            parent = Topic.find_by(id: parent_id)
            if parent
              current_alts = Array(parent.custom_fields["alternates"]).map(&:to_i)
              unless current_alts.include?(topic.id)
                current_alts << topic.id
                parent.custom_fields["alternates"] = current_alts
                parent.save_custom_fields
              end

              # Удаляем текущий топик из alternates других родителей
              Topic.where.not(id: parent.id).find_each do |other|
                next if other.custom_fields["alternates"].blank?
                other_alts = Array(other.custom_fields["alternates"]).map(&:to_i)
                if other_alts.include?(topic.id)
                  other_alts.delete(topic.id)
                  other.custom_fields["alternates"] = other_alts
                  other.save_custom_fields
                end
              end
            end
          end
        end

        # Возвращаем унифицированный респонс для фронта
        alternates
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

      # Добавляет выбранные топики в массив доступных, если их там нет
      def ensure_selected_included(formatted, selected_ids)
        existing_ids = formatted.map { |t| t[:value] }
        selected_ids.compact.each do |id|
          next if existing_ids.include?(id)
          t = Topic.find_by(id: id)
          next unless t
          cat = t.category
          lang_id = category_language_id(cat)
          lang = DiscourseCategoryLanguage::Language.find_by(id: lang_id)
          formatted << {
            value: t.id,
            label: "#{t.id}: #{t.title} (#{cat.id}: #{cat.name} [#{lang_id}: #{lang&.slug}])",
            disabled: false
          }
        end
        formatted
      end
    end
  end
end
