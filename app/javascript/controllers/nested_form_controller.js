import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
		this.weapons = document.getElementById("weapons")
  }

	add(event) {
		event.preventDefault()
		debugger

		const template = document.getElementById("weapon-wrapper-template")
		const wrapper = template.innerHTML
		this.weapons.appendChild(wrapper)
	}

	remove(event) {
    event.preventDefault()

    const wrapper = event.target.closest(".weapon-wrapper")
    if (wrapper) {
      wrapper.remove()
    }
  }
}
