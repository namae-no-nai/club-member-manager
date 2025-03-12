import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select2"];

  connect() {
    debugger
    this.select2Targets.forEach(element => {
      element.select2();
    });
  }
}
