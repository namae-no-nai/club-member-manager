import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        partnerIds: Array,
        disableFingerprint: Boolean // Add this new static value
    }

    connect() {
        this.boundCheckFingerprint = this.checkFingerprint.bind(this)
        window.addEventListener("partner:changed", this.boundCheckFingerprint);

        this.checkFingerprint()
    }

    disconnect() {
        window.removeEventListener("partner:changed", this.boundCheckFingerprint);
    }

    checkFingerprint(event) {
        // If fingerprint verification is globally disabled, always hide the notice.
        if (this.disableFingerprintValue) {
            this.element.classList.add('hidden');
            return;
        }

        let selectedPartnerId;

        if (event && event.detail && event.detail.partnerId) {
            selectedPartnerId = parseInt(event.detail.partnerId);
        } else {
            const partnerSelect = document.querySelector('select[name="event[partner_id]"]')
            if (!partnerSelect) return
            selectedPartnerId = parseInt(partnerSelect.value)
        }

        if (selectedPartnerId && this.partnerIdsValue.includes(selectedPartnerId)) {
            this.element.classList.remove('hidden')
        } else {
            this.element.classList.add('hidden')
        }
    }
}


