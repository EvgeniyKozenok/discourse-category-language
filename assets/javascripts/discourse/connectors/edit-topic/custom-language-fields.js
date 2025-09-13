import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";

export default class CustomLanguageFields extends Component {
  @tracked availableTopics = [];
  @tracked selectedTopic = null;      // для одиночного селекта
  @tracked selectedTopics = [];       // для мультиселекта
  @tracked isAlternates = true;       // по умолчанию

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

      this.availableTopics = data.topics || [];
      this.isAlternates = data.is_alternates;

      // Подставляем текущие значения из buffered
      const current = this.args.buffered?.topic_alternates || [];

      if (this.isAlternates) {
        // мультиселект — массив
        this.selectedTopics = this.availableTopics.filter(t => current.includes(t.value));
      } else {
        // одиночный селект — первый id
        const selectedId = current[0] || null;
        this.selectedTopic = this.availableTopics.find(t => t.value === selectedId) || null;
      }
    } catch (e) {
      console.error("Failed to load alternates", e);
    }
    console.log("this.availableTopics ", this.availableTopics);
    console.log("this.selectedTopics ", this.selectedTopics);
    console.log("this.selectedTopic ", this.selectedTopic);
    console.log("this.isAlternates ", this.isAlternates);
  }

  @action
  searchTopics(query) {
    // ComboBox передает введенный текст
    this.loadAlternates(query);
  }

  @action
  onChangeTopics(selectedArray) {
    // мультиселект возвращает массив объектов
    this.selectedTopics = selectedArray;
    const ids = selectedArray.map(t => t.value);
    console.log("onChangeTopics", ids);
    return;
    this.args.buffered.set("topic_alternates", ids);
  }

  @action
  onChangeTopic(selected) {
    // одиночный селект возвращает объект
    this.selectedTopic = selected;
    console.log("onChangeTopic", selected);
    return;
    this.args.buffered.set("topic_alternates", selected ? [selected.value] : []);
  }
}
