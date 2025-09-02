/* eslint-disable ember/no-classic-components */
import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";
import ComboBox from "select-kit/components/combo-box";

console.log("CategoryLanguageSettings: Component loaded");

export default class CategoryLanguageSettings extends Component {
  @service siteSettings;

  @action
  onChange(value) {
    console.log("Selected language:", value);
    this.set("category.custom_fields.language", value);
  }

  get availableLanguages() {
    // В идеале, список языков должен браться из настроек Discourse.
    // Пока мы используем простой статический список для тестирования.
    return [
      { name: "English", value: "en" },
      { name: "Русский", value: "ru" },
      { name: "Deutsch", value: "de" },
      { name: "Français", value: "fr" },
    ];
  }
}
