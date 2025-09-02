# frozen_string_literal: true

module DiscourseCategoryLanguage
  module Admin
    class AdminCategoryLanguageController < ::Admin::AdminController
      requires_plugin ::DiscourseCategoryLanguage::PLUGIN_NAME

      def list
        render json: { languages: languages }
      end

      private

      def languages
        [
          { id: 1, name: "English", slug: "en" },
          { id: 2, name: "Russian", slug: "ru" }
        ]
      end
    end
  end
end
