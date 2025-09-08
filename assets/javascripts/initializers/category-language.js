// assets/javascripts/initializers/category-language.js
import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";

export default {
  name: "category-language",
  initialize() {
    withPluginApi("0.8.7", (api) => {
      const siteSettings = api.container.lookup("service:siteSettings");

      const categoryCache = new Map();

      function updateHtmlLang(categoryId) {
        const slug = categoryCache.get(categoryId);
        const el = document.documentElement
        const lang = 'lang'
        if (el.getAttribute(lang) === slug) {
          console.log("SPA lang (no change):", slug);
          return;
        }
        el.setAttribute(lang, slug);
      }

      api.onPageChange(async () => {
        const topics = document.querySelectorAll("[data-topic-id]");
        if (!topics || topics.length === 0) return;

        const firstTopicId = topics[0].dataset.topicId;
        if (!firstTopicId) return;

        const topicData = await ajax(`/t/${firstTopicId}.json`);
        const categoryId = topicData?.category_id;
        if (!categoryId) return;

        if (categoryCache.has(categoryId)) {
          console.log("SPA lang (from cache):", categoryCache.get(categoryId));
          updateHtmlLang(categoryId);
          return;
        }

        const categoryData = await ajax(`/c/${categoryId}/show.json`);
        const languageId =
          categoryData?.category?.custom_fields?.language_id ||
          siteSettings.discourse_category_language_default_id;

        const { slug } = await ajax(
          `/admin/discourse-category-language/get-slug/${languageId}`
        );

        categoryCache.set(categoryId, slug);

        console.log("SPA lang (fetched):", slug);
        updateHtmlLang(categoryId);
      });
    });
  },
};
