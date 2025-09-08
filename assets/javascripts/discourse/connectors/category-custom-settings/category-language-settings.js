// app/assets/javascripts/components/category-language-settings.js
import Component from "@ember/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import I18n from "I18n";

export default class CategoryLanguageSettings extends Component {
  @service siteSettings;

  @tracked availableLanguages = [];
  @tracked selectedLanguage = null;
  @tracked label = I18n.t("discourse_category_language.label");

  constructor() {
    super(...arguments);
    this.loadLanguages();
  }

  async loadLanguages() {
    try {
      const response = await ajax("/admin/discourse-category-language/list");

      this.availableLanguages = response.languages.map((l) => ({
        label: l.name,
        value: l.id,
      }));

      const defaultId = this.siteSettings.discourse_category_language_default_id;
      console.log("Default language ID:", defaultId);
      const selectedId = this.category.custom_fields.language_id || defaultId;

      this.selectedLanguage = this.availableLanguages.find(
        (l) => +l.value === +selectedId
      );

      if (!this.selectedLanguage) {
        this.selectedLanguage = this.availableLanguages.find(
          (l) => +l.value === +defaultId
        );
      }
    } catch (err) {
      this.availableLanguages = [];
      this.selectedLanguage = null;
    }
  }

  @action
  onChange(newLanguageId) {
    this.set("category.custom_fields.language_id", newLanguageId);
    this.category.save();
  }
}
