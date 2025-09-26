# frozen_string_literal: true

module DiscourseCategoryLanguage
  module Admin
    class AdminCategoryLanguageController < ::Admin::AdminController
      requires_plugin ::DiscourseCategoryLanguage::PLUGIN_NAME

      # GET /admin/discourse-category-language/list
      def list
        languages = DiscourseCategoryLanguage::Language.order(:id)

        selected_id = nil
        if params[:category_id].present?
          category = Category.find_by(id: params[:category_id])

          if category
            selected_id =
              category.custom_fields["language_id"] ||
              category.parent_category&.custom_fields&.dig("language_id") ||
              ::DiscourseCategoryLanguage::DEFAULT_LANGUAGE_ID
          end
        end

        render json: {
          languages: languages.as_json(only: [:id, :name, :slug]),
          selected_id: selected_id
        }
      end

      # POST /admin/discourse-category-language
      def create
        language = DiscourseCategoryLanguage::Language.new(language_params)
        if language.save
          render json: { language: language.as_json(only: [:id, :name, :slug]) }
        else
          render json: { errors: language.errors.full_messages }, status: 422
        end
      end

      # PATCH /admin/discourse-category-language/:id
      def update
        language = DiscourseCategoryLanguage::Language.find(params[:id])

        if language.update(language_params)
          render json: { language: language.as_json(only: [:id, :name, :slug]) }
        else
          render json: { errors: language.errors.full_messages }, status: 422
        end
      end

      # DELETE /admin/discourse-category-language/:id
      def destroy
        language = DiscourseCategoryLanguage::Language.find(params[:id])

        if language.id == ::DiscourseCategoryLanguage::DEFAULT_LANGUAGE_ID
          render json: { error: I18n.t("admin_js.admin.errors.cannot_delete_default") }, status: 403
          return
        end

        # removing custom category fields
        CategoryCustomField.where(name: 'language_id', value: language.id).delete_all

        # removing custom topic fields
        TopicCustomField.where(name: 'language_id', value: language.id).delete_all

        language.destroy
        render json: { success: true }
      end

      private

      def language_params
        params.require(:language).permit(:name, :slug)
      end
    end
  end
end
