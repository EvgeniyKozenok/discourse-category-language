# frozen_string_literal: true

DiscourseCategoryLanguage::Engine.routes.draw do
  get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw { mount ::DiscourseCategoryLanguage::Engine, at: "discourse-category-language" }
