// assets/javascripts/initializers/category-language.js
import { ajax } from "discourse/lib/ajax";
import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "category-language",
  initialize() {
    withPluginApi("0.8.7", (api) => {
      const categoryCache = new Map();
      let isLoaded = true;
      let defaultSlug = "";

      function updateHtmlLang(slug) {
        if (!slug || typeof slug !== "string") {
          return;
        }
        const el = document.documentElement;
        if (el.getAttribute("lang") === slug) {
          return;
        }
        el.setAttribute("lang", slug);
      }

      function updateAlternateLinks(alternates) {
        if (isLoaded) {
          // Only update the first time the SPA is loaded
          // Render with server side rendered content
          //isLoaded = false;
          return;
        }

        document
          .querySelectorAll('link[rel="alternate"]')
          .forEach((el) => el.remove());
        Object.entries(alternates).forEach(([lang, url]) => {
          const link = document.createElement("link");
          link.rel = "alternate";
          link.hreflang = lang;
          link.href = url;
          document.head.appendChild(link);
        });
      }

      function getEntityFromUrl() {
        const path = window.location.pathname;
        let match, entityId, entityType;

        // Topic URL: /t/:slug/:topicId(/:postNumber)?
        match = path.match(/\/t\/[^/]+\/(\d+)/);
        if (match) {
          entityId = match[1];
          entityType = "topic";
          return { entityId, entityType };
        }

        // Category URL: /c/:slug/.../:categoryId
        match = path.match(/\/c\/.*\/(\d+)/);
        if (match) {
          entityId = match[1];
          entityType = "category";
          return { entityId, entityType };
        }

        return null;
      }

      api.onPageChange(async () => {
        const entity = getEntityFromUrl();
        if (!entity) {
          if (defaultSlug.length) {
            updateHtmlLang(defaultSlug);
            updateAlternateLinks({});
          }
          return;
        }

        const { entityId, entityType } = entity;

        if (categoryCache.has(entityId)) {
          const cached = categoryCache.get(entityId);
          updateHtmlLang(cached.slug);
          updateAlternateLinks(cached.alternates);
          return;
        }

        const { slug, alternates, default_slug } = await ajax(
          `/discourse-category-language/spa-meta/${entityId}/${entityType}`
        );

        defaultSlug = default_slug;

        categoryCache.set(entityId, { slug, alternates });

        if (!slug) {
          return;
        }

        updateHtmlLang(slug);
        updateAlternateLinks(alternates);
      });
    });
  },
};
