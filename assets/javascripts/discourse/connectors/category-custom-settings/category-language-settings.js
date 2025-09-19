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

  languageLabel = i18n("discourse_category_language.label");
  alternatesLabel = i18n("discourse_category_language.alternates_label");
  defaultCategoryLabel = i18n("discourse_category_language.default_label");

  // --- Another private function to save language ---
  #saveChangeCategoryLanguage = async (newLanguageId) => {
    // We save the language on the server (and get the updated language_id)
    try {
      const response = await ajax(
        `/admin/discourse-category-language/categories/${this.category.id}`,
        {
          type: "PATCH",
          data: { language_id: newLanguageId },
        }
      );

      this.category.custom_fields.language_id =
        response.language_id || this.category.custom_fields.language_id;
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

    // Let's update the UI
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
        // Resetting connections for the current category (the server will disable the rest)
        try {
          await ajax(
            `/admin/discourse-category-language/categories/${this.category.id}`,
            {
              type: "PATCH",
              data: { x_defaults: null, alternates: [] },
            }
          );
        } catch (err) {
          popupAjaxError({
            jqXHR: {
              responseJSON: {
                errors: ["Error clear category relations: " + err.message],
              },
            },
          });
          return;
        }

        // Let's update locally so we don't keep old values
        this.category.custom_fields.x_defaults = null;
        this.category.custom_fields.alternates = [];

        await this.#saveChangeCategoryLanguage(newLanguageId);
      },
    });
  };

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

  get isDefaultLanguage() {
    return this.getCategoryLanguageId === this.intDefaultLanguageId;
  }

  // --- Loading language list ---
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
      const response = await ajax(
        "/admin/discourse-category-language/categories"
      );

      // we form available options (label/value/disabled)
      const allCats = response.categories || [];

      // first filter: exclude current category
      let candidates = allCats.filter((c) => +c.id !== +this.category.id);

      // then filter by language:
      // - if current category is default: available - those with language != default
      // - otherwise: available - those with language == default
      candidates = candidates.filter((c) => {
        const categoryLangId =
          c.language_id != null ? +c.language_id : this.intDefaultLanguageId;
        return this.isDefaultLanguage
          ? categoryLangId !== this.intDefaultLanguageId
          : categoryLangId === this.intDefaultLanguageId;
      });

      // map to format { label, value, disabled }
      const prepared = candidates.map((c) => {
        let disabled = false;
        if (this.isDefaultLanguage && c.x_defaults) {
          disabled = true;
        }

        // insert language tag (name [slug])
        const lang = this.availableLanguages.find(
          (l) =>
            +l.value ===
            +(c.language_id !== undefined && c.language_id !== null
              ? c.language_id
              : this.intDefaultLanguageId)
        );
        const langLabel = lang ? ` (${lang.label})` : "";

        return {
          label: `${c.name}${langLabel}`,
          value: +c.id,
          disabled,
        };
      });

      this.availableCategories = prepared;

      if (this.isDefaultLanguage) {
        const rawCurrent = this.category.custom_fields.alternates || [];
        const currentAlternates = rawCurrent.map
          ? rawCurrent.map(Number)
          : Array.from(rawCurrent).map(Number);

        // we leave in selected only those ids that are actually in the list of availableCategories
        const availIds = new Set(this.availableCategories.map((c) => +c.value));
        this.selectedAlternates = currentAlternates.filter((id) =>
          availIds.has(+id)
        );
        this.selectedDefaultCategory = null;
      } else {
        // x_defaults (id)
        const defaultId = this.category.custom_fields.x_defaults
          ? +this.category.custom_fields.x_defaults
          : null;

        // if the selected default is not in availableCategories - add it to the beginning (for display)
        if (
          defaultId &&
          !this.availableCategories.find((c) => +c.value === +defaultId)
        ) {
          const selectedCategory = allCats.find((c) => +c.id === +defaultId);
          if (selectedCategory) {
            const lang = this.availableLanguages.find(
              (l) =>
                +l.value ===
                +(selectedCategory.language_id !== undefined &&
                selectedCategory.language_id !== null
                  ? selectedCategory.language_id
                  : this.intDefaultLanguageId)
            );
            const langLabel = lang ? ` (${lang.label})` : "";
            this.availableCategories = [
              {
                label: `${selectedCategory.name}${langLabel}`,
                value: +selectedCategory.id,
                disabled: false,
              },
              ...this.availableCategories,
            ];
          }
        }

        this.selectedDefaultCategory = defaultId;
        this.selectedAlternates = [];
      }
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
    // selectedIds comes as an array of values (numbers or strings)
    const ids = (selectedIds || []).map((v) => +v);
    const data = {};

    if (this.isDefaultLanguage) {
      data.alternates = ids;
      data.x_defaults = null;
    } else {
      data.x_defaults = ids.length > 0 ? ids[0] : null;
      data.alternates = [];
    }

    try {
      const response = await ajax(
        `/admin/discourse-category-language/categories/${this.category.id}`,
        {
          type: "PATCH",
          data,
        }
      );

      // Update local custom_fields based on server response
      this.category.custom_fields.language_id =
        response.language_id || this.category.custom_fields.language_id;
      this.category.custom_fields.alternates = response.alternates || [];
      this.category.custom_fields.x_defaults = response.x_defaults || null;

      // Restarting connections (and UI)
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
    const hasRelations =
      !!this.category.custom_fields.x_defaults ||
      (Array.isArray(this.category.custom_fields.alternates) &&
        this.category.custom_fields.alternates.length > 0);

    if (hasRelations) {
      await this.#saveChangeCategoryLanguageAndClearOldRelations(newLanguageId);
    } else {
      await this.#saveChangeCategoryLanguage(newLanguageId);
    }
  }
}
