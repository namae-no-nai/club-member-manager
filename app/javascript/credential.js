import * as WebAuthnJSON from "@github/webauthn-json"
import { showMessage } from "messenger";

function getCSRFToken() {
  debugger
  var CSRFSelector = document.querySelector('meta[name="csrf-token"]')
  if (CSRFSelector) {
    return CSRFSelector.getAttribute("content")
  } else {
    return null
  }
}

function callback(url, body) {
  fetch(url, {
    method: "POST",
    body: JSON.stringify(body),
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-CSRF-Token": getCSRFToken()
    },
    credentials: 'same-origin'
  }).then(function(response) {
    if (response.ok) {
      window.location.replace("/")
    } else if (response.status < 500) {
      response.text().then(showMessage);
    } else {
      showMessage("Sorry, something wrong happened.");
    }
  });
}

function create(callbackUrl, credentialOptions) {
  const publicKey = {
    // The challenge is produced by the server; see the Security Considerations
    challenge: new Uint8Array([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29]),

    // Relying Party:
    rp: {
      name: "Clube dos amiguinho"
    },

    // User:
    user: {
      id: Uint8Array.from(window.atob("MIIBkzCCATigAwIBAjCCAZMwggE4oAMCAQIwggGTMII="), c=>c.charCodeAt(0)),
      name: "alex.mueller@example.com",
      displayName: "Alex Müller",
    },

    // This Relying Party will accept either an ES256 or RS256 credential, but
    // prefers an ES256 credential.
    pubKeyCredParams: [
      {
        type: "public-key",
        alg: -7 // "ES256" as registered in the IANA COSE Algorithms registry
      },
      {
        type: "public-key",
        alg: -257 // Value registered by this specification for "RS256"
      }
    ],

    authenticatorSelection: {
      // Try to use UV if possible. This is also the default.
      userVerification: "preferred"
    },

    timeout: 360000,  // 6 minutes
    excludeCredentials: [],

    // Make excludeCredentials check backwards compatible with credentials registered with U2F
    // extensions: {"appidExclude": "https://acme.example.com"}
  };

  debugger
  navigator.credentials.create({ publicKey })
  .then(function (newCredentialInfo) {
    // Send new credential info to server for verification and registration.
  }).catch(function (err) {
    debugger
    // No acceptable authenticator or user refused consent. Handle appropriately.
  });

  // WebAuthnJSON.create({ "publicKey": credentialOptions }).then(function(credential) {
  //   callback(callbackUrl, credential);
  // }).catch(function(error) {
  //   debugger
  //   showMessage(error);
  // });

  console.log("Creating new public key credential...");
}

function get(credentialOptions) {
  WebAuthnJSON.get({ "publicKey": credentialOptions }).then(function(credential) {
    callback("/session/callback", credential);
  }).catch(function(error) {
    showMessage(error);
  });

  console.log("Getting public key credential...");
}

export { create, get }
