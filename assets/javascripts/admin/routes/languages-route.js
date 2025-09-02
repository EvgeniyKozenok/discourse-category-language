import Route from "@ember/routing/route";

export default class Languages extends Route {
  model() {
    return this.store.findAll("language");
  }
}
