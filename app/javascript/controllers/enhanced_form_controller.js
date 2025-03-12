import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    $('.select2').select2();
  }
}
