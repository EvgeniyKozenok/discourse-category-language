# frozen_string_literal: true
# lib/discourse_category_language/helpers_loader.rb

module ::DiscourseCategoryLanguage
  class HelpersLoader
    def self.prepend_helpers
      # Load all helper modules from the helpers directory
      Dir[File.expand_path("helpers/*.rb", __dir__)].sort.each do |file|
        require_dependency file
      end

      # prepend
      [
        :HtmlLangHelper,
        :MetaHelper,
        :CategoryLookup,
        :AlternateLinks
      ].each do |mod|
        const = "DiscourseCategoryLanguage::Helpers::#{mod}".safe_constantize
        ::ApplicationHelper.prepend(const) if const
      end
    end
  end
end
