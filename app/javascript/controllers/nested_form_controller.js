import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
		console.log("TEu cu")
  }

	add(event) {
		event.preventDefault()

		const template = document.getElementById("weapon-wrapper-template")
		const wrapper = template.innerHTML
		document.getElementById("weapons").insertAdjacentHTML('beforebegin', wrapper)
	}

	remove(event) {
    event.preventDefault()

    const wrapper = event.target.closest(".weapon-wrapper")
    if (wrapper) {
      wrapper.remove()
    }
  }
}
