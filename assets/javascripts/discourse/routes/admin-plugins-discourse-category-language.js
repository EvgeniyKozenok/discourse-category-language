import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class AdminPluginsDiscourseCategoryLanguageRoute extends Route {
  async model() {
    try {
      // Запрос к бэкенду для получения списка языков
      const response = await ajax("/admin/discourse-category-language/list");
      console.log("Loaded languages:", response);
      return response.languages;
    } catch (error) {
      // Если запрос не удался, выводим ошибку в консоль для отладки
      console.error("Ошибка при загрузке языков:", error);
      popupAjaxError(error);
      return [];
    }
  }

  setupController(controller, model) {
    // Устанавливаем данные в контроллер
    controller.languages = model;
  }
}
