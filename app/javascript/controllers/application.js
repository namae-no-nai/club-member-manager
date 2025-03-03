import { Application } from "@hotwired/stimulus"
import NestedFormController from "./controllers/nested_form_controller"


const application = Application.start()
application.register("nested-form", NestedFormController)

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
