import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class AdminPluginsDiscourseCategoryLanguageRoute extends Route {
  async model() {
    try {
      const response = await ajax("/admin/discourse-category-language/list");
      return response.languages;
    } catch (error) {
      popupAjaxError(error);
      return [];
    }
  }

  setupController(controller, model) {
    controller.languages = model;
  }
}
