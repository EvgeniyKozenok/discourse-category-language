# config/routes.rb
# frozen_string_literal: true

DiscourseCategoryLanguage::Engine.routes.draw do
  get "/" => "/admin/plugins#index"
  get "/spa-meta/:id/:entity" => "admin/admin_category_language#spa_meta"
  get "/list" => "admin/admin_category_language#list"
  post "/" => "admin/admin_category_language#create"
  patch "/:id" => "admin/admin_category_language#update"
  delete "/:id" => "admin/admin_category_language#destroy"

  get "/categories" => "admin/admin_category_relations#index"
  patch "/categories/:id" => "admin/admin_category_relations#update"
end

Discourse::Application.routes.draw do
  scope "/admin/discourse-category-language", constraints: StaffConstraint.new do
    mount ::DiscourseCategoryLanguage::Engine, at: "/"
  end
end
