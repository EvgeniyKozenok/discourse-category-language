# frozen_string_literal: true
# app/controllers/discourse_category_language/admin/admin_category_relations_controller.rb

module DiscourseCategoryLanguage
  module Admin
    class AdminCategoryRelationsController < ::Admin::AdminController
      requires_plugin ::DiscourseCategoryLanguage::PLUGIN_NAME

      # GET /admin/discourse-category-language/categories
      def index
        categories = Category.all.select(:id, :name, :slug).map do |c|
          {
            id: c.id,
            name: c.name,
            slug: c.slug,
            language_id: c.custom_fields["language_id"],
            alternates: Array(c.custom_fields["alternates"]).map(&:to_i),
            x_defaults: c.custom_fields["x_defaults"]&.to_i
          }
        end
        render json: { categories: categories }
      end

      # PATCH /admin/discourse-category-language/categories/:id
      def update
        category = Category.find_by(id: params[:id])
        raise Discourse::NotFound unless category

        # correct parsing of parameters (accounting for nil / "null" / strings)
        language_id = params.key?(:language_id) ? params[:language_id].to_i : nil
        alternates  = params.key?(:alternates) && params[:alternates].present? ? Array(params[:alternates]).map(&:to_i) : nil
        x_defaults  = params.key?(:x_defaults) && params[:x_defaults].present? ? params[:x_defaults].to_i : nil

        ActiveRecord::Base.transaction do
          if x_defaults
            #
            # CASE 1: assign x_defaults (the current category becomes a child)
            #
            category.custom_fields.delete("alternates")
            category.custom_fields["x_defaults"] = x_defaults
            category.save_custom_fields

            # Add a category to the default alts
            default_category = Category.find_by(id: x_defaults)
            if default_category
              default_alts = Array(default_category.custom_fields["alternates"]).map(&:to_i)
              if default_alts.exclude?(category.id)
                default_alts << category.id
                default_category.custom_fields["alternates"] = default_alts
                default_category.save_custom_fields
              end
            end

            # remove the current category from other alts
            Category.where.not(id: [category.id, x_defaults]).find_each do |c|
              next if c.custom_fields["alternates"].blank?
              current_alts = Array(c.custom_fields["alternates"]).map(&:to_i)
              if current_alts.delete(category.id)
                c.custom_fields["alternates"] = current_alts
                c.save_custom_fields
              end
            end

            # Reset x_defaults for those who referred to this category as default
            Category.where.not(id: [category.id, x_defaults]).find_each do |c|
              if c.custom_fields["x_defaults"].to_i == category.id
                c.custom_fields["x_defaults"] = nil
                c.save_custom_fields
              end
            end

          elsif alternates
            #
            # CASE 2: assign alternates (the current category becomes the default)
            #
            current_language_id = category.custom_fields["language_id"]&.to_i
            default_language_id = ::DiscourseCategoryLanguage::DEFAULT_LANGUAGE_ID

            if current_language_id.present? && default_language_id.present? && current_language_id != default_language_id
              raise Discourse::InvalidParameters.new("Only default-language category can have alternates")
            end

            # 1. Save the list of alts in the default
            category.custom_fields["alternates"] = alternates
            category.custom_fields["x_defaults"] = nil
            category.save_custom_fields

            # 2. We clean up overlapping alt and extra x_defaults for the others
            Category.where.not(id: category.id).find_each do |c|
              if c.custom_fields["alternates"].present?
                current_alts = Array(c.custom_fields["alternates"]).map(&:to_i)
                new_alts = current_alts - alternates
                if new_alts != current_alts
                  c.custom_fields["alternates"] = new_alts
                  c.save_custom_fields
                end
              end

              if c.custom_fields["x_defaults"].to_i == category.id && !alternates.include?(c.id)
                c.custom_fields["x_defaults"] = nil
                c.save_custom_fields
              end
            end

            # 3. And only after cleaning we assign x_defaults to children
            Category.where(id: alternates).find_each do |c|
              c.custom_fields["x_defaults"] = category.id
              c.save_custom_fields
            end
          end

          # Update the language_id if it arrived.
          category.custom_fields["language_id"] = language_id if language_id
          category.save_custom_fields
        end

        render json: {
          id: category.id,
          language_id: category.custom_fields["language_id"],
          alternates: Array(category.custom_fields["alternates"]).map(&:to_i),
          x_defaults: category.custom_fields["x_defaults"]&.to_i
        }
      end
    end
  end
end
