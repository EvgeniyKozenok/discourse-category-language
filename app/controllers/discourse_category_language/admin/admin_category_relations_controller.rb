# frozen_string_literal: true
# app/controllers/discourse_category_language/admin/admin_category_relations_controller.rb

module DiscourseCategoryLanguage
  module Admin
    class AdminCategoryRelationsController < ::Admin::AdminController
      requires_plugin ::DiscourseCategoryLanguage::PLUGIN_NAME

      # GET /admin/discourse-category-language/categories/:id
      def index
        c = Category.find(params[:id])
        is_alts = alternates_mode?(c)

        # select candidates for selection
        categories_scope = Category.where.not(id: c.id).includes(:parent_category)

        candidates = categories_scope.select do |cat|
          lang_id = category_language_id(cat, allow_default: false)
          if is_alts
            # for default categories - only the explicitly specified language != default
            lang_id.present?
          else
            # for non-default categories - only categories with a default language or no language
            lang_id.nil? || lang_id == default_language_id
          end
        end

        categories = candidates.map do |cat|
          lang_id = category_language_id(cat)
          lang = ::DiscourseCategoryLanguage::Language.find_by(id: lang_id)
          lang_label = lang ? "#{lang.slug}:#{lang.id}" : lang_id.to_s

          {
            value: cat.id,
            label: "#{cat.name} (#{lang_label})",
            disabled: false
          }
        end

        render json: {
          categories: categories,
          is_alternates: is_alts,
          x_defaults: is_alts ? nil : c.custom_fields["x_defaults"]&.to_i,
          selected: is_alts ? Array(c.custom_fields["alternates"]).map(&:to_i) : []
        }
      end

      # PATCH /admin/discourse-category-language/categories/:id
      def update
        category = Category.find_by(id: params[:id])
        raise Discourse::NotFound unless category

        # we determine the mode: default (alternates) or not (x_defaults)
        is_alts = alternates_mode?(category)

        language_id = params.key?(:language_id) ? params[:language_id].to_i : nil
        alternates  = params.key?(:alternates) ? Array(params[:alternates]).map(&:to_i) : []
        x_defaults  = params.key?(:x_defaults) ? params[:x_defaults].to_i : nil

        ActiveRecord::Base.transaction do
          if is_alts
            #
            # Default category: managing alternates
            #
            category.custom_fields["alternates"] = alternates
            category.custom_fields["x_defaults"] = nil
            category.save_custom_fields

            # For each alternative category, we assign x_defaults to the current category.
            Category.where(id: alternates).find_each do |alt_cat|
              alt_cat.custom_fields["x_defaults"] = category.id
              alt_cat.save_custom_fields
            end

            # Remove the current category from the alternates of all other categories
            # and reset x_defaults if they reference the current category
            Category.where.not(id: [category.id] + alternates).find_each do |c|
              if c.custom_fields["alternates"].present?
                new_alts = Array(c.custom_fields["alternates"]).map(&:to_i) - [category.id]
                if new_alts != Array(c.custom_fields["alternates"]).map(&:to_i)
                  c.custom_fields["alternates"] = new_alts
                  c.save_custom_fields
                end
              end

              if c.custom_fields["x_defaults"].to_i == category.id
                c.custom_fields["x_defaults"] = nil
                c.save_custom_fields
              end
            end

          else
            #
            # Non-default category: manage x_defaults
            #
            category.custom_fields["alternates"] = nil
            category.custom_fields["x_defaults"] = x_defaults
            category.save_custom_fields

            if x_defaults
              default_category = Category.find_by(id: x_defaults)
              if default_category
                default_alts = Array(default_category.custom_fields["alternates"]).map(&:to_i)
                default_alts << category.id unless default_alts.include?(category.id)
                default_category.custom_fields["alternates"] = default_alts
                default_category.save_custom_fields
              end
            end

            # Remove the current category from the alternates of all other categories
            Category.where.not(id: [category.id, x_defaults].compact).find_each do |c|
              if c.custom_fields["alternates"].present?
                new_alts = Array(c.custom_fields["alternates"]).map(&:to_i) - [category.id]
                if new_alts != Array(c.custom_fields["alternates"]).map(&:to_i)
                  c.custom_fields["alternates"] = new_alts
                  c.save_custom_fields
                end
              end

              # Reset x_defaults for categories that referred to the current category
              if c.custom_fields["x_defaults"].to_i == category.id
                c.custom_fields["x_defaults"] = nil
                c.save_custom_fields
              end
            end
          end

          # We update the language if it arrives
          if language_id
            old_language_id = category_language_id(category)
            category.custom_fields["language_id"] = language_id
            category.save_custom_fields

            new_is_default = (language_id == default_language_id)
            old_is_default = (old_language_id == default_language_id)

            if old_is_default && !new_is_default
              # Language changed from default -> non-default
              # 1. Clear alternates for current category
              category.custom_fields["alternates"] = nil
              category.save_custom_fields

              # 2. Remove current category as x_defaults in other non-default categories
              Category.where.not(id: category.id).find_each do |c|
                if c.custom_fields["x_defaults"].to_i == category.id
                  c.custom_fields["x_defaults"] = nil
                  c.save_custom_fields
                end
              end

            elsif !old_is_default && new_is_default
              # Language changed to default
              # 1. Clear x_defaults for current category
              x_def = category.custom_fields["x_defaults"]&.to_i
              category.custom_fields["x_defaults"] = nil
              category.save_custom_fields

              # 2. Remove current category from alternates of previous default category
              if x_def
                prev_default = Category.find_by(id: x_def)
                if prev_default && prev_default.custom_fields["alternates"].present?
                  prev_alts = Array(prev_default.custom_fields["alternates"]).map(&:to_i)
                  if prev_alts.delete(category.id)
                    prev_default.custom_fields["alternates"] = prev_alts
                    prev_default.save_custom_fields
                  end
                end
              end
            end
          end

        end

        render json: { success: true }
      end


      private

      def default_language_id
        @default_language_id ||= ::DiscourseCategoryLanguage::DEFAULT_LANGUAGE_ID
      end

      def category_language_id(category, allow_default: true)
        raw = category.custom_fields["language_id"].presence ||
              category.parent_category&.custom_fields&.[]("language_id")
        lang_id = raw.to_i
        if lang_id > 0
          lang_id
        else
          allow_default ? default_language_id : nil
        end
      end

      def alternates_mode?(category)
        category_language_id(category) == default_language_id
      end
    end
  end
end
