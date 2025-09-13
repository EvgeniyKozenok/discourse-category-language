# app/controllers/discourse_category_language/admin/admin_category_relations_controller.rb
# frozen_string_literal: true

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
        alternates = params.key?(:alternates) && params[:alternates].present? ? Array(params[:alternates]).map(&:to_i) : nil
        x_defaults = params.key?(:x_defaults) && params[:x_defaults].present? ? params[:x_defaults].to_i : nil

        ActiveRecord::Base.transaction do
          # CASE: assign x_defaults (current non-default language category)
          if x_defaults
            # Remove alternates from the current category (it is now a child)
            category.custom_fields.delete("alternates")
            category.custom_fields["x_defaults"] = x_defaults
            category.save_custom_fields

            # For parent (default language category), add the current category to its alternates
            default_category = Category.find_by(id: x_defaults)
            if default_category
              default_alts = Array(default_category.custom_fields["alternates"]).map(&:to_i)
              unless default_alts.include?(category.id)
                default_alts << category.id
                default_category.custom_fields["alternates"] = default_alts
                default_category.save_custom_fields
              end
            end

            # Remove the current category from alternates for all other categories
            Category.where.not(id: [category.id, x_defaults]).find_each do |c|
              next if c.custom_fields["alternates"].blank?
              current_alts = Array(c.custom_fields["alternates"]).map(&:to_i)
              if current_alts.include?(category.id)
                current_alts.delete(category.id)
                c.custom_fields["alternates"] = current_alts
                c.save_custom_fields
              end
            end

            #  If some categories had x_defaults pointing to the current one (i.e. the current one was previously the default),
            # then these links are now incorrect - reset their x_defaults.
            Category.where.not(id: [category.id, x_defaults]).find_each do |c|
              if c.custom_fields["x_defaults"].to_i == category.id
                c.custom_fields["x_defaults"] = nil
                c.save_custom_fields
              end
            end

            # CASE: assign alternates (current category becomes default)
          elsif alternates
            current_language_id = category.custom_fields["language_id"]&.to_i
            default_language_id = SiteSetting.default_language_id rescue nil

            if current_language_id.present? && default_language_id.present? && current_language_id != default_language_id
              raise Discourse::InvalidParameters.new("Only default-language category can have alternates")
            end

            # Save alternates to the current category
            category.custom_fields["alternates"] = alternates
            category.custom_fields["x_defaults"] = nil
            category.save_custom_fields

            # For each category from the alternates list, set x_defaults = category.id
            Category.where(id: alternates).find_each do |c|
              c.custom_fields["x_defaults"] = category.id
              c.save_custom_fields
            end

            # We remove these alternates from other defaults, and for those who had x_defaults == category.id but not in the alternates list,
            # we reset them
            Category.where.not(id: category.id).find_each do |c|
              # удалить выбранные alt-ид из alternates других дефолтных
              if c.custom_fields["alternates"].present?
                current_alts = Array(c.custom_fields["alternates"]).map(&:to_i)
                new_alts = current_alts - alternates
                if new_alts != current_alts
                  c.custom_fields["alternates"] = new_alts
                  c.save_custom_fields
                end
              end

              # if someone's x_defaults points to the current category, but its id is not in alternates - reset
              if c.custom_fields["x_defaults"].to_i == category.id && !alternates.include?(c.id)
                c.custom_fields["x_defaults"] = nil
                c.save_custom_fields
              end
            end
          end

          # We update the category language if a parameter has arrived
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
