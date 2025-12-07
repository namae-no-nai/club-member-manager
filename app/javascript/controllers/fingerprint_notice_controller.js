import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        partnerIds: Array
    }

    connect() {
        this.checkFingerprint()
    }

    checkFingerprint() {
        const partnerSelect = document.querySelector('select[name="event[partner_id]"]')
        if (!partnerSelect) return

        const selectedPartnerId = parseInt(partnerSelect.value)

        if (selectedPartnerId && this.partnerIdsValue.includes(selectedPartnerId)) {
            this.element.classList.remove('hidden')
        } else {
            this.element.classList.add('hidden')
        }
    }
}

