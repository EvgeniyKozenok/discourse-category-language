// assets/javascripts/discourse/connectors/category-custom-settings/category-language-settings.js
import { tracked } from "@glimmer/tracking";
import Component from "@ember/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class CategoryLanguageSettings extends Component {
  @service siteSettings;
  @service dialog;

  @tracked availableLanguages = [];
  @tracked selectedLanguage = null;
  @tracked availableCategories = [];
  @tracked selectedAlternates = []; // array id (numbers)
  @tracked selectedDefaultCategory = null; // id (number) or null
  @tracked isCategoryWithDefaultLanguage = true;
  @tracked isManualRelationsActive = false;

  languageLabel = i18n("discourse_category_language.label");
  alternatesLabel = i18n("discourse_category_language.alternates_label");
  defaultCategoryLabel = i18n("discourse_category_language.default_label");

  // --- Another private function to save language ---
  #saveChangeCategoryLanguage = async (newLanguageId) => {
    try {
      await ajax(this.#getHandleUrl(), {
        type: "PATCH",
        data: { language_id: newLanguageId },
      });
      this.category.custom_fields.language_id = newLanguageId;
    } catch (err) {
      popupAjaxError({
        jqXHR: {
          responseJSON: {
            errors: ["Error saving language: " + err.message],
          },
        },
      });
      return;
    }

    await this.loadRelations();
  };

  #saveChangeCategoryLanguageAndClearOldRelations = async (newLanguageId) => {
    const lang = this.availableLanguages.find(
      (l) => +l.value === +newLanguageId
    );
    await this.dialog.yesNoConfirm({
      message: i18n("js.discourse_category_language.confirm_language_change", {
        name: lang ? lang.label : newLanguageId,
      }),
      didConfirm: async () => {
        await this.#saveChangeCategoryLanguage(newLanguageId);
      },
    });
  };

  #getHandleUrl = () =>
    `/admin/discourse-category-language/categories/${this.category.id}`;

  constructor() {
    super(...arguments);
    this.loadRelations();
  }

  get intDefaultLanguageId() {
    return +this.siteSettings.discourse_category_language_default_id;
  }

  get getCategoryLanguageId() {
    const currentLangId = this.category.custom_fields.language_id;
    return currentLangId !== undefined
      ? +currentLangId
      : this.intDefaultLanguageId;
  }

  async loadLanguages() {
    try {
      const response = await ajax("/admin/discourse-category-language/list");
      this.availableLanguages = response.languages.map((l) => ({
        label: `${l.name} [${l.slug}]`,
        value: +l.id,
      }));

      this.selectedLanguage =
        this.availableLanguages.find(
          (l) => +l.value === this.getCategoryLanguageId
        ) ||
        this.availableLanguages.find(
          (l) => +l.value === this.intDefaultLanguageId
        );
    } catch (err) {
      popupAjaxError(err);
      this.availableLanguages = [];
      this.selectedLanguage = null;
    }
  }

  // --- Loading categories and preparing availableCategories and selectedAlternates ---
  async loadRelations() {
    await this.loadLanguages();

    try {
      const response = await ajax(this.#getHandleUrl());

      this.availableCategories = response.categories;
      this.selectedAlternates = response.selected;
      this.selectedDefaultCategory = response.x_defaults;
      this.isCategoryWithDefaultLanguage = response.is_alternates;
    } catch (err) {
      popupAjaxError(err);
      this.availableCategories = [];
      this.selectedAlternates = [];
      this.selectedDefaultCategory = null;
    }
  }

  // --- Saving alternates / x_defaults ---
  @action
  async onChangeAlternates(selectedIds) {
    const data = {};
    if (this.isCategoryWithDefaultLanguage) {
      data.alternates = (selectedIds || []).map((v) => +v);
      data.x_defaults = null;
    } else {
      data.x_defaults = selectedIds;
      data.alternates = [];
    }

    try {
      await ajax(this.#getHandleUrl(), {
        type: "PATCH",
        data,
      });

      await this.loadRelations();
    } catch (err) {
      popupAjaxError({
        jqXHR: {
          responseJSON: {
            errors: ["Error saving category relations: " + err.message],
          },
        },
      });
    }
  }

  // --- Change category language (with confirmation if there are links) ---
  @action
  async onChange(newLanguageId) {
    if (
      (this.isCategoryWithDefaultLanguage && this.selectedAlternates.length) ||
      (!this.isCategoryWithDefaultLanguage && this.selectedDefaultCategory)
    ) {
      await this.#saveChangeCategoryLanguageAndClearOldRelations(newLanguageId);
    } else {
      await this.#saveChangeCategoryLanguage(newLanguageId);
    }
  }
}
