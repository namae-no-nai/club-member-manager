import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static outlets = [ "fingerprintNotice" ]

  connect() {
    $('.select2').select2();
    $('.select2.partner-select').on('change', (event) => {
      this.updateWeapons(event);

      const customEvent = new CustomEvent("partner:changed", {
        detail: { partnerId: event.target.value }
      });
      window.dispatchEvent(customEvent);
    });
  }

	add(event) {
		event.preventDefault()

    const weaponSelect = document.querySelector('select[name="practices[][weapon_id]"]');
		const template = document.getElementById("weapon-wrapper-template");
    const clonedContent = document.importNode(template.content, true);
    clonedContent.querySelector('select[name="practices[][weapon_id]"]').innerHTML = weaponSelect.innerHTML;
		document.getElementById("weapons").appendChild(clonedContent);
    $('.select2').select2();
	}

  updateWeapons(event) {
    const headers = { "Content-Type": "application/json" };

    fetch(`/weapons?partner_id=${event.target.value}`, { headers })
          .then(response => response.json())
          .then(data => {
            const selectElements = document.querySelectorAll('select[name="practices[][weapon_id]"]');
            selectElements.forEach( selectElement => {
              selectElement.innerHTML = '<option value="">Selecione a Arma</option>';
              data.forEach(weapon => {
                const option = document.createElement('option');
                option.value = weapon.id;
                option.textContent = weapon.friendly_name;
                selectElement.appendChild(option);
              });
              $(selectElement).select2();
            })
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
