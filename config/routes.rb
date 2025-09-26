# frozen_string_literal: true
# config/routes.rb

DiscourseCategoryLanguage::Engine.routes.draw do
  get "/spa-meta/:id/:entity" => "public_category_language#spa_meta"

  scope "/admin", constraints: StaffConstraint.new do
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
end

Discourse::Application.routes.draw do
  mount ::DiscourseCategoryLanguage::Engine, at: "/discourse-category-language"
end
