import { Controller } from "@hotwired/stimulus"
import * as Credential from "credential";

import { MDCTextField } from '@material/textfield';

export default class extends Controller {
  static targets = ["usernameField"]

  connect(){
    console.log('AI mEU Caralho')
  }

  create(event) {
    var [data, status, xhr] = event.detail;
    console.log(data);
    var credentialOptions = data;

    // Registration
    if (credentialOptions["user"]) {
      debugger
      var credential_nickname = "teste" // event.target.querySelector("input[name='registration[nickname]']").value;
      var callback_url = `/partners/register?credential_nickname=${credential_nickname}`

      Credential.create(encodeURI(callback_url), credentialOptions);
    }
  }

  error(event) {
    let response = event.detail[0];
    let usernameField = new MDCTextField( "deu ruim"); //this.usernameFieldTarget);
    usernameField.valid = false;
    usernameField.helperTextContent = response["errors"][0];
  }
}