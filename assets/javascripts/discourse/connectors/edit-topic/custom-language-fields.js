import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";

export default class CustomLanguageFields extends Component {
  @tracked availableTopics = [];
  @tracked selectedTopic = null;      // одиночный селект
  @tracked selectedTopics = [];       // мультиселект
  @tracked isAlternates = true;

  constructor() {
    super(...arguments);
    this.loadAlternates(""); // начальный список
  }

  async loadAlternates(query = "") {
    const topicId = this.args.buffered?.get?.("id");
    if (!topicId) return;

    try {
      const data = await ajax(`/admin/discourse-category-language/topics/${topicId}/alternates`, {
        data: { q: query }
      });

      this.updateFromResponse(data);

    } catch (e) {
      console.error("Failed to load alternates", e);
      this.clearState();
    }
  }

  @action
  async onChangeTopic(selected) {
    this.selectedTopic = selected;
    const topicId = this.args.buffered?.get?.("id");
    if (!topicId || !selected) return;

    try {
      const data = await ajax(`/admin/discourse-category-language/topics/${topicId}/${selected}/assign_default`, {
        method: "PATCH",
      });

      this.updateFromResponse(data);

    } catch (e) {
      console.error("Failed to assign default topic", e);
      this.clearState();
    }
  }

  @action
  searchTopics(query) {
    this.loadAlternates(query);
  }

  @action
  onChangeTopics(selectedArray) {
    this.selectedTopics = selectedArray;
    const ids = selectedArray.map(t => t.value);
    console.log("onChangeTopics", ids);
    return;
  }

  // --- вспомогательные методы ---

  updateFromResponse(data) {
    // availableTopics
    const topicsChanged = !this.arraysEqual(
      this.availableTopics.map(t => t.value),
      (data.topics || []).map(t => t.value)
    );
    if (topicsChanged) {
      this.availableTopics = data.topics || [];
    }

    // isAlternates
    if (this.isAlternates !== data.is_alternates) {
      this.isAlternates = data.is_alternates;
    }

    // selectedTopics
    const selectedTopicsIds = (data.selected_topics || []).map(t => t.value ?? t);
    const currentSelectedIds = (this.selectedTopics || []).map(t => t.value ?? t);
    if (!this.arraysEqual(currentSelectedIds, selectedTopicsIds)) {
      this.selectedTopics = data.selected_topics || [];
    }

    // selectedTopic
    const selectedTopicId = data.selected_topic ?? null;
    if ((this.selectedTopic?.value ?? null) !== selectedTopicId) {
      this.selectedTopic = this.availableTopics.find(t => t.value === selectedTopicId) || null;
    }
  }

  clearState() {
    this.availableTopics = [];
    this.selectedTopic = null;
    this.selectedTopics = [];
    this.isAlternates = true;
  }

  arraysEqual(a, b) {
    if (a.length !== b.length) return false;
    for (let i = 0; i < a.length; i++) {
      if (a[i] !== b[i]) return false;
    }
    return true;
  }
}
