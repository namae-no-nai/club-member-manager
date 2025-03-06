import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
  }

	add(event) {
		event.preventDefault()

		const template = document.getElementById("weapon-wrapper-template")
		const wrapper = template.innerHTML
		document.getElementById("weapons").insertAdjacentHTML('afterend', wrapper)
	}

	remove(event) {
    event.preventDefault()

    const wrapper = event.target.closest(".weapon-wrapper")
    if (wrapper) {
      wrapper.remove()
    }
  }
}
