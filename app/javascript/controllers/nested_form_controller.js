import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    $('.select2').select2();
    $('.select2').on('change', (event) => {
      this.updateWeapons(event);
    });
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
          .then(data => {
            const selectElement = document.querySelector('select[name="practices[][weapon_id]"]');
            selectElement.innerHTML = '<option value="">Selecione a Arma</option>';
            data.forEach(weapon => {
              const option = document.createElement('option');
              option.value = weapon.id;
              option.textContent = weapon.friendly_name;
              selectElement.appendChild(option);
            });
            $(selectElement).select2();
          })
  }

	remove(event) {
    event.preventDefault()

    const wrapper = event.target.closest(".weapon-wrapper")
    if (wrapper) {
      wrapper.remove()
    }
  }
}
