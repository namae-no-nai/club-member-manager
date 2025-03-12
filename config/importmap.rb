# Pin npm packages by running ./bin/importmap
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@7.1.2/app/assets/javascripts/rails-ujs.esm.js"

pin "@material/list", to: "https://ga.jspm.io/npm:@material/list@4.0.0/dist/mdc.list.js"
pin "@material/menu", to: "https://ga.jspm.io/npm:@material/menu@4.0.0/dist/mdc.menu.js"
pin "@material/snackbar", to: "https://ga.jspm.io/npm:@material/snackbar@4.0.0/dist/mdc.snackbar.js"
pin "@material/textfield", to: "https://ga.jspm.io/npm:@material/textfield@4.0.0/dist/mdc.textfield.js"
pin "@material/top-app-bar", to: "https://ga.jspm.io/npm:@material/top-app-bar@4.0.0/dist/mdc.topAppBar.js"
pin "@github/webauthn-json", to: "@github--webauthn-json.js" # @2.1.1

pin_all_from "app/javascript/controllers", under: "controllers"
pin "credential"
pin "messenger"
pin "select2" # @4.1.0
pin "jquery" # @3.7.1
