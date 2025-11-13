import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["video", "canvas", "photo", "startButton", "allowButton", "input", "cameraSection", "captureButton", "submitButton"]
  static values = { 
    width: { type: Number, default: 720 },
    showSectionButton: { type: Boolean, default: false }
  }

  connect() {
    this.height = 0
    this.streaming = false
    this.videoStream = null
    this.capturedImageData = null

    if (this.hasPhotoTarget) {
      this.clearPhoto()
    }

    // Set up form cleanup
    const form = this.element.closest("form")
    if (form) {
      this.boundCleanup = () => this.cleanup()
      form.addEventListener("submit", this.boundCleanup)
    }

    // Clean up on page unload
    this.boundBeforeUnload = () => this.cleanup()
    window.addEventListener("beforeunload", this.boundBeforeUnload)
  }


  showCameraSection() {
    if (this.hasCameraSectionTarget) {
      this.cameraSectionTarget.style.display = "block"
    }
  }

  async requestCamera() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ 
        video: true, 
        audio: false 
      })
      
      this.videoStream = stream
      this.videoTarget.srcObject = stream
      this.videoTarget.play()
      
      if (this.hasAllowButtonTarget) {
        this.allowButtonTarget.style.display = "none"
      }
      this.videoTarget.style.display = "block"
      
      if (this.hasStartButtonTarget) {
        this.startButtonTarget.style.display = "block"
      }
    } catch (err) {
      console.error(`An error occurred: ${err}`)
      alert("Erro ao acessar a câmera: " + err.message)
    }
  }

  videoCanPlay() {
    if (!this.streaming && this.videoTarget) {
      this.height = this.videoTarget.videoHeight / (this.videoTarget.videoWidth / this.widthValue)

      this.videoTarget.setAttribute("width", this.widthValue)
      this.videoTarget.setAttribute("height", this.height)
      this.canvasTarget.setAttribute("width", this.widthValue)
      this.canvasTarget.setAttribute("height", this.height)
      this.streaming = true
    }
  }

  capture() {
    if (!this.hasCanvasTarget || !this.hasPhotoTarget) return

    const context = this.canvasTarget.getContext("2d")
    if (this.widthValue && this.height) {
      this.canvasTarget.width = this.widthValue
      this.canvasTarget.height = this.height
      context.drawImage(this.videoTarget, 0, 0, this.widthValue, this.height)

      const data = this.canvasTarget.toDataURL("image/png")
      this.photoTarget.setAttribute("src", data)
      this.photoTarget.style.display = "block"
      
      // Store base64 data
      this.capturedImageData = data
      
      if (this.hasInputTarget) {
        this.inputTarget.value = data
      }

      // Show submit button if it exists
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.style.display = "block"
      }
    } else {
      this.clearPhoto()
    }
  }

  clearPhoto() {
    if (!this.hasCanvasTarget || !this.hasPhotoTarget) return

    const context = this.canvasTarget.getContext("2d")
    context.fillStyle = "#aaaaaa"
    context.fillRect(0, 0, this.canvasTarget.width, this.canvasTarget.height)

    const data = this.canvasTarget.toDataURL("image/png")
    this.photoTarget.setAttribute("src", data)
  }

  submitCapture(event) {
    event.preventDefault()
    
    if (!this.capturedImageData) {
      alert("Por favor, capture uma foto primeiro.")
      return
    }

    // Get submit URL from button's data attribute
    const submitUrl = event.currentTarget.dataset.submitUrl || event.currentTarget.getAttribute("data-submit-url")
    
    if (!submitUrl) {
      alert("URL de submissão não encontrada.")
      return
    }

    // Create a form to submit the image
    const form = document.createElement("form")
    form.method = "POST"
    form.action = submitUrl
    
    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')
    if (csrfToken) {
      const csrfInput = document.createElement("input")
      csrfInput.type = "hidden"
      csrfInput.name = "authenticity_token"
      csrfInput.value = csrfToken.getAttribute("content")
      form.appendChild(csrfInput)
    }

    // Add biometric_proof parameter
    const imageInput = document.createElement("input")
    imageInput.type = "hidden"
    imageInput.name = "biometric_proof"
    imageInput.value = this.capturedImageData
    form.appendChild(imageInput)

    document.body.appendChild(form)
    form.submit()
  }

  cleanup() {
    if (this.videoStream) {
      this.videoStream.getTracks().forEach(track => track.stop())
      this.videoStream = null
    }
  }

  disconnect() {
    this.cleanup()
    
    // Remove event listeners
    if (this.boundBeforeUnload) {
      window.removeEventListener("beforeunload", this.boundBeforeUnload)
    }
    
    const form = this.element.closest("form")
    if (form && this.boundCleanup) {
      form.removeEventListener("submit", this.boundCleanup)
    }
  }
}

