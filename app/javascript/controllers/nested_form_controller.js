import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    $('.select2').select2();
  }

	add(event) {
		event.preventDefault()

		const template = document.getElementById("weapon-wrapper-template")
		const wrapper = template.innerHTML
		document.getElementById("weapons").insertAdjacentHTML('beforeend', wrapper)
    $('.select2').select2();
	}

	remove(event) {
    event.preventDefault()

    const wrapper = event.target.closest(".weapon-wrapper")
    if (wrapper) {
      wrapper.remove()
    }
  }
}
