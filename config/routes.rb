# frozen_string_literal: true
# config/routes.rb

DiscourseCategoryLanguage::Engine.routes.draw do
  get "/" => "/admin/plugins#index"
  get "/list" => "admin/admin_category_language#list"
  post "/" => "admin/admin_category_language#create"
  patch "/:id" => "admin/admin_category_language#update"
  delete "/:id" => "admin/admin_category_language#destroy"

  get "/categories/:id" => "admin/admin_category_relations#index"
  patch "/categories/:id" => "admin/admin_category_relations#update"

  get "/topics/:id/alternates" => "admin/admin_topic_relations#alternates"
  patch "/topics/:id/alternates_update" => "admin/admin_topic_relations#alternates_update"
  patch "/topics/:id/:x_default/assign_default" => "admin/admin_topic_relations#assign_default"
end

Discourse::Application.routes.draw do
  get "/discourse-category-language/spa-meta/:id/:entity" => "discourse_category_language/public_category_language#spa_meta"

  scope "/admin/discourse-category-language", constraints: StaffConstraint.new do
    mount ::DiscourseCategoryLanguage::Engine, at: "/"
  end
end
