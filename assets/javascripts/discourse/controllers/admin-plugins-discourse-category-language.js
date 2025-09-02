import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";

export default class AdminPluginsDiscourseCategoryLanguageController extends Controller {
  @tracked languages = [];
  @tracked showModal = false;
  @tracked editingLanguage = null;
  @tracked newLanguageName = "";
  @tracked newLanguageSlug = "";

  actions = {
    addLanguage() {
      this.editingLanguage = null;
      this.newLanguageName = "";
      this.newLanguageSlug = "";
      this.showModal = true;
    },

    editLanguage(language) {
      this.editingLanguage = language;
      this.newLanguageName = language.name;
      this.newLanguageSlug = language.slug;
      this.showModal = true;
    },

    deleteLanguage(language) {
      if (language.id === 1) {
        console.warn("Cannot delete default language.");
        return;
      }

      this.languages = this.languages.filter(lang => lang.id !== language.id);
      // Здесь будет отправка запроса на сервер для удаления
      console.log("Deleted language:", language);
    },

    closeModal() {
      this.showModal = false;
    },

    saveLanguage() {
      if (!this.newLanguageName || !this.newLanguageSlug) {
        // Логика обработки ошибок
        return;
      }

      if (this.editingLanguage) {
        this.editingLanguage.name = this.newLanguageName;
        this.editingLanguage.slug = this.newLanguageSlug;
        // Здесь будет отправка запроса на сервер для обновления
        console.log("Updated language:", this.editingLanguage);
      } else {
        const newId = this.languages.length > 0 ? Math.max(...this.languages.map(lang => lang.id)) + 1 : 1;
        const newLanguage = { id: newId, name: this.newLanguageName, slug: this.newLanguageSlug };
        this.languages.push(newLanguage);
        // Здесь будет отправка запроса на сервер для создания
        console.log("Created new language:", newLanguage);
      }

      this.showModal = false;
    }
  };
}
