# frozen_string_literal: true
# lib/discourse_category_language/patches/application_controller_skip_skeleton.rb

module ::DiscourseCategoryLanguage
  module ApplicationControllerSkipSkeleton
    def render(*args, **kwargs, &block)
      if defined?(@skip_precompiled) && @skip_precompiled
        kwargs[:template] ||= "layouts/application"
      end
      super(*args, **kwargs, &block)
    end
  end
end
