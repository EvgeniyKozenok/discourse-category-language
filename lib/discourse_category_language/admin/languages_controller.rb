# lib/discourse_category_language/admin/languages_controller.rb

module DiscourseCategoryLanguage
  class Admin::LanguagesController < Admin::AdminController
    def index
      render json: { languages: SiteSetting.available_locales.map { |l| { id: l.to_s, name: l.to_s } } }
    end
  end
end
