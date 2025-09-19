// assets/javascripts/discourse/controllers/admin-plugins-discourse-category-language.js
import { tracked } from "@glimmer/tracking";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class AdminPluginsDiscourseCategoryLanguageController extends Controller {
  @service dialog;

  @tracked languages = [];
  @tracked showModal = false;
  @tracked editingLanguage = null;
  @tracked newLanguageName = "";
  @tracked newLanguageSlug = "";

  constructor() {
    super(...arguments);
    this.loadLanguages();
  }

  async loadLanguages() {
    const response = await ajax("/admin/discourse-category-language/list");
    this.languages = response.languages;
  }

  @action
  addLanguage() {
    this.editingLanguage = null;
    this.newLanguageName = "";
    this.newLanguageSlug = "";
    this.showModal = true;
  }

  @action
  editLanguage(language) {
    this.editingLanguage = language;
    this.newLanguageName = language.name;
    this.newLanguageSlug = language.slug;
    this.showModal = true;
  }

  @action
  async deleteLanguage(language) {
    await this.dialog.yesNoConfirm({
      message: i18n("js.discourse_category_language.confirm_delete", {
        name: language.name,
      }),
      didConfirm: async () => {
        const DEFAULT_LANGUAGE_ID =
          this.siteSettings.discourse_category_language_default_id;
        if (language.id === DEFAULT_LANGUAGE_ID) {
          popupAjaxError({
            jqXHR: {
              responseJSON: {
                errors: ["Cannot delete default language."],
              },
            },
          });
          return;
        }
        try {
          await ajax(`/admin/discourse-category-language/${language.id}`, {
            type: "DELETE",
          });
          this.languages = this.languages.filter((l) => l.id !== language.id);
        } catch (err) {
          popupAjaxError({
            jqXHR: {
              responseJSON: {
                errors: ["Error delete language:" + err.message],
              },
            },
          });
        }
      },
    });
  }

  @action
  closeModal() {
    this.showModal = false;
  }

  @action
  async saveLanguage() {
    if (!this.newLanguageName || !this.newLanguageSlug) {
      popupAjaxError({
        jqXHR: {
          responseJSON: {
            errors: [i18n("js.discourse_category_language.name_slug_required")],
          },
        },
      });
      return;
    }

    const slugExists = this.languages.some(
      (l) =>
        l.slug === this.newLanguageSlug &&
        (!this.editingLanguage || l.id !== this.editingLanguage.id)
    );
    if (slugExists) {
      popupAjaxError({
        jqXHR: {
          responseJSON: {
            errors: [i18n("js.discourse_category_language.slug_exists")],
          },
        },
      });
      return;
    }

    try {
      if (this.editingLanguage) {
        const response = await ajax(
          `/admin/discourse-category-language/${this.editingLanguage.id}`,
          {
            type: "PATCH",
            data: {
              language: {
                name: this.newLanguageName,
                slug: this.newLanguageSlug,
              },
            },
          }
        );

        this.languages = this.languages.map((l) =>
          l.id === this.editingLanguage.id ? response.language : l
        );
      } else {
        const response = await ajax("/admin/discourse-category-language", {
          type: "POST",
          data: {
            language: {
              name: this.newLanguageName,
              slug: this.newLanguageSlug,
            },
          },
        });
        this.languages = [...this.languages, response.language];
      }

      this.showModal = false;
    } catch (err) {
      popupAjaxError({
        jqXHR: {
          responseJSON: {
            errors: ["Error saving language: " + err.message],
          },
        },
      });
    }
  }
}
