import Model, { attr } from "@ember-data/model";

export default class Language extends Model {
  @attr("string") id;
  @attr("string") name;
}
