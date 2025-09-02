# frozen_string_literal: true

module DiscourseCategoryLanguage
  module Admin
    class AdminCategoryLanguageController < ::Admin::AdminController
      requires_plugin ::DiscourseCategoryLanguage::PLUGIN_NAME

      # GET /admin/discourse-category-language/list
      def list
        languages = DiscourseCategoryLanguage::Language.order(:id)
        render json: { languages: languages.as_json(only: [:id, :name, :slug]) }
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
