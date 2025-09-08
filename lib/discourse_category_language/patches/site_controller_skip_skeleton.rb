# lib/discourse_category_language/patches/site_controller_skip_skeleton.rb

module ::DiscourseCategoryLanguage
  module SiteControllerSkipSkeleton
    def site
      path = request.path.to_s
      base = Discourse.base_path.to_s
      base = "" if base == "/"
      if params[:disable_skeleton] || path.match?(%r{\A#{Regexp.escape(base)}/(t|c)/})
        @skip_precompiled = true
        Rails.logger.info("discourse-category-language: skip_precompiled=true for #{path}")
      end
      super
    end
  end
end
