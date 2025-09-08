import { withPluginApi } from "discourse/lib/plugin-api";
import Site from "discourse/models/site";

export default {
  name: "extend-site-settings-category-language",
  initialize() {
    withPluginApi("1.8.0", (api) => {
      const siteSettings = api.container.lookup("service:site-settings");

      Object.defineProperty(siteSettings, "discourse_category_language_default_id", {
        get() {
          return Site.current().discourse_category_language_default_id;
        },
      });
    });
  },
};
