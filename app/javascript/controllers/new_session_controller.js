import { Controller } from "@hotwired/stimulus";
import * as webauthn from "@github/webauthn-json";

export default class extends Controller {
  static targets = ["usernameField"]

  async create(event) {
    const [data, status, xhr] = event.detail;
    const credentialOptions = data;

    console.log("Credential options:", credentialOptions);

    try {
      const assertion = await webauthn.get(credentialOptions);
      console.log("Assertion:", assertion);

      const response = await fetch("/sessions/callback", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ credential: assertion })
      });

      if (response.ok) {
        const data = await response.json();
        window.location.href = data.redirect_to;
      } else {
        const error = await response.text();
        console.error("Erro de registro:", error);
      }

    } catch (error) {
      console.error("WebAuthn prompt failed", error);
    }
  }

  error(event) {
    let response = event.detail[0];
    let usernameField = new MDCTextField(this.usernameFieldTarget);
    usernameField.valid = false;
    usernameField.helperTextContent = response["errors"][0];
  }
}
