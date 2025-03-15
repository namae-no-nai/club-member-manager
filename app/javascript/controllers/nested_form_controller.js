import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    $('.select2').select2();
    // const partnerSelection = document.getElementById("event_partner_id");
    // partnerSelection.addEventListener("change", this.updateWeapons)
  }

	add(event) {
		event.preventDefault()

		const template = document.getElementById("weapon-wrapper-template")
		const wrapper = template.innerHTML
		document.getElementById("weapons").insertAdjacentHTML('beforeend', wrapper)
    $('.select2').select2();
	}

  updateWeapons(event) {
    const headers = { "Content-Type": "application/json" };

    fetch(`/weapons?partner_id=${event.target.value}`, { headers })
          .then(response => response.json())
          .then(data => console.log(data));
  }

	remove(event) {
    event.preventDefault()

    const wrapper = event.target.closest(".weapon-wrapper")
    if (wrapper) {
      wrapper.remove()
    }
  }
}
