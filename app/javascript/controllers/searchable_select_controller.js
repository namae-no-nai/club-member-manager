import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]
  static values = {
    placeholder: String,
    searchPlaceholder: { type: String, default: "Search..." }
  }

  connect() {
    this.originalSelect = this.selectTarget
    this.isOpen = false
    this.filteredOptions = []
    this.selectedValue = this.originalSelect.value
    this.selectedText = this.getSelectedText()

    // Ensure the select has required attribute if it has a prompt option
    // This prevents form submission when prompt is selected
    if (this.hasPromptOption() && !this.originalSelect.hasAttribute('required')) {
      this.originalSelect.setAttribute('required', 'required')
    }

    // Check if wrapper already exists (Turbo cache restoration)
    // Look for wrapper that's the previous sibling of the select element
    let prevSibling = this.originalSelect.previousElementSibling
    if (prevSibling && prevSibling.hasAttribute('data-searchable-select-wrapper')) {
      // Reuse existing wrapper
      this.wrapper = prevSibling
      this.displayButton = this.wrapper.querySelector('[data-searchable-select-display]')
      this.displayText = this.displayButton.querySelector('span')
      this.menu = this.wrapper.querySelector('[data-searchable-select-menu]')
      this.searchInput = this.menu.querySelector('input')
      this.optionsContainer = this.menu.querySelector('[data-searchable-select-options]')
      // Refresh options in case they changed
      this.populateOptions()
    } else {
      // Remove any orphaned wrappers in the parent first
      const orphanedWrappers = this.originalSelect.parentNode.querySelectorAll('[data-searchable-select-wrapper]')
      orphanedWrappers.forEach(wrapper => wrapper.remove())
      // Create new wrapper
      this.buildCustomSelect()
    }

    this.hideOriginalSelect()
    this.setupEventListeners()
    this.updateDisplay()
    this.setupFormValidation()
  }

  disconnect() {
    this.removeEventListeners()

    // Remove form validation listener
    if (this.formSubmitHandler && this.originalSelect) {
      const form = this.originalSelect.closest('form')
      if (form) {
        form.removeEventListener('submit', this.formSubmitHandler, false)
      }
    }

    // Clean up the wrapper when disconnecting
    if (this.wrapper && this.wrapper.parentNode) {
      this.wrapper.remove()
    }

    // Restore original select visibility
    if (this.originalSelect) {
      this.originalSelect.style.position = ''
      this.originalSelect.style.opacity = ''
      this.originalSelect.style.pointerEvents = ''
      this.originalSelect.style.width = ''
      this.originalSelect.style.height = ''
    }
  }

  buildCustomSelect() {
    // Create the custom dropdown structure
    this.wrapper = document.createElement('div')
    this.wrapper.className = 'relative'
    this.wrapper.setAttribute('data-searchable-select-wrapper', '')

    // Display button
    this.displayButton = document.createElement('button')
    this.displayButton.type = 'button'
    this.displayButton.className = 'form-select w-full mt-1 p-2 border border-gray-300 rounded-md bg-white text-left flex items-center justify-between'
    this.displayButton.setAttribute('data-action', 'click->searchable-select#toggle')
    this.displayButton.setAttribute('data-searchable-select-display', '')

    const displayText = document.createElement('span')
    displayText.className = 'truncate'
    this.displayText = displayText
    displayText.textContent = this.selectedText || this.placeholderValue || 'Select an option...'
    this.displayButton.appendChild(displayText)

    const arrow = document.createElement('span')
    arrow.className = 'ml-2 text-gray-500'
    arrow.innerHTML = '▼'
    this.displayButton.appendChild(arrow)

    // Dropdown menu
    this.menu = document.createElement('div')
    this.menu.className = 'absolute z-50 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg hidden'
    this.menu.setAttribute('data-searchable-select-menu', '')

    // Search input
    this.searchInput = document.createElement('input')
    this.searchInput.type = 'text'
    this.searchInput.className = 'w-full p-2 border-b border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500'
    this.searchInput.placeholder = this.searchPlaceholderValue
    this.searchInput.setAttribute('data-action', 'input->searchable-select#filter click->searchable-select#stopPropagation keydown->searchable-select#handleKeydown')

    // Options container
    this.optionsContainer = document.createElement('div')
    this.optionsContainer.className = 'max-h-60 overflow-y-auto'
    this.optionsContainer.setAttribute('data-searchable-select-options', '')

    this.menu.appendChild(this.searchInput)
    this.menu.appendChild(this.optionsContainer)

    this.wrapper.appendChild(this.displayButton)
    this.wrapper.appendChild(this.menu)

    this.originalSelect.parentNode.insertBefore(this.wrapper, this.originalSelect)
    this.populateOptions()
  }

  populateOptions() {
    if (!this.optionsContainer) return

    this.optionsContainer.innerHTML = ''
    const options = Array.from(this.originalSelect.options)

    if (options.length === 0) {
      const noOptions = document.createElement('div')
      noOptions.className = 'px-3 py-2 text-gray-500 text-sm'
      noOptions.textContent = 'No options available'
      this.optionsContainer.appendChild(noOptions)
      this.filteredOptions = []
      return
    }

    options.forEach((option, index) => {
      const optionElement = document.createElement('div')
      optionElement.className = `px-3 py-2 cursor-pointer hover:bg-gray-100 ${option.value === this.selectedValue ? 'bg-blue-50 text-blue-600' : ''}`
      optionElement.textContent = option.text
      optionElement.setAttribute('data-value', option.value)
      optionElement.setAttribute('data-action', 'click->searchable-select#select')

      if (option.value === this.selectedValue) {
        optionElement.classList.add('font-semibold')
      }

      this.optionsContainer.appendChild(optionElement)
    })

    this.filteredOptions = Array.from(this.optionsContainer.children)
  }

  hideOriginalSelect() {
    this.originalSelect.style.position = 'absolute'
    this.originalSelect.style.opacity = '0'
    this.originalSelect.style.pointerEvents = 'none'
    this.originalSelect.style.width = '1px'
    this.originalSelect.style.height = '1px'
  }

  setupEventListeners() {
    document.addEventListener('click', this.handleOutsideClick.bind(this))
  }

  removeEventListeners() {
    document.removeEventListener('click', this.handleOutsideClick.bind(this))
  }

  handleOutsideClick(event) {
    if (this.wrapper && !this.wrapper.contains(event.target)) {
      this.close()
    }
  }

  toggle(event) {
    event.stopPropagation()
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    if (!this.menu || !this.searchInput) return
    this.isOpen = true
    this.menu.classList.remove('hidden')
    this.searchInput.focus()
    this.searchInput.value = ''
    this.filter()
  }

  close() {
    if (!this.menu || !this.searchInput) return
    this.isOpen = false
    this.menu.classList.add('hidden')
    this.searchInput.value = ''
    this.filter()
  }

  filter() {
    if (!this.searchInput || !this.filteredOptions) return
    const searchTerm = this.searchInput.value.toLowerCase()

    this.filteredOptions.forEach(option => {
      const text = option.textContent.toLowerCase()
      const matches = text.includes(searchTerm)
      option.style.display = matches ? 'block' : 'none'
    })
  }

  select(event) {
    event.stopPropagation()
    const option = event.currentTarget
    const value = option.getAttribute('data-value')
    const text = option.textContent

    this.selectedValue = value
    this.selectedText = text

    // Update original select
    this.originalSelect.value = value
    this.originalSelect.dispatchEvent(new Event('change', { bubbles: true }))

    // Remove validation error if a valid option was selected
    if (!this.isEmptyValue(value)) {
      this.hideValidationError()
      this.displayButton.classList.remove('border-red-500', 'ring-2', 'ring-red-500')
      this.displayButton.classList.add('border-gray-300')
    }

    this.updateDisplay()
    this.populateOptions()
    this.close()
  }

  updateDisplay() {
    if (!this.displayText || !this.displayButton) return

    // If empty value (prompt selected), show placeholder
    if (this.isEmptyValue(this.selectedValue)) {
      this.displayText.textContent = this.placeholderValue || this.selectedText || 'Select an option...'
      this.displayButton.classList.add('text-gray-500')
      this.displayButton.classList.remove('text-gray-900')
    } else {
      this.displayText.textContent = this.selectedText
      this.displayButton.classList.remove('text-gray-500')
      this.displayButton.classList.add('text-gray-900')
    }
  }

  getSelectedText() {
    const selectedOption = this.originalSelect.options[this.originalSelect.selectedIndex]
    return selectedOption ? selectedOption.text : ''
  }

  hasPromptOption() {
    // Check if the first option has an empty value (typical prompt pattern)
    const firstOption = this.originalSelect.options[0]
    return firstOption && firstOption.value === ''
  }

  isEmptyValue(value) {
    // Treat empty string, null, undefined, or whitespace-only as empty
    return !value || value.toString().trim() === ''
  }

  setupFormValidation() {
    // Find the form that contains this select
    const form = this.originalSelect.closest('form')
    if (!form) return

    // Add validation on form submit
    this.formSubmitHandler = (event) => {
      // Get the current value from the select (not cached)
      const currentValue = this.originalSelect.value
      if (this.isEmptyValue(currentValue)) {
        event.preventDefault()
        event.stopPropagation()

        // Add visual feedback
        if (this.displayButton) {
          this.displayButton.classList.add('border-red-500', 'ring-2', 'ring-red-500')
          this.displayButton.classList.remove('border-gray-300')
        }

        // Show validation message
        this.showValidationError()

        // Remove error styling after a delay
        setTimeout(() => {
          if (this.displayButton) {
            this.displayButton.classList.remove('border-red-500', 'ring-2', 'ring-red-500')
            this.displayButton.classList.add('border-gray-300')
          }
        }, 3000)
      } else {
        // Remove error styling if value is valid
        if (this.displayButton) {
          this.displayButton.classList.remove('border-red-500', 'ring-2', 'ring-red-500')
          this.displayButton.classList.add('border-gray-300')
        }
        this.hideValidationError()
      }
    }

    form.addEventListener('submit', this.formSubmitHandler, false)
  }

  showValidationError() {
    // Remove existing error message if any
    this.hideValidationError()

    // Create error message element
    const errorMsg = document.createElement('p')
    errorMsg.className = 'mt-1 text-sm text-red-600'
    errorMsg.textContent = 'Por favor, selecione uma opção válida'
    errorMsg.setAttribute('data-searchable-select-error', '')

    // Insert after the wrapper
    this.wrapper.parentNode.insertBefore(errorMsg, this.wrapper.nextSibling)
  }

  hideValidationError() {
    if (!this.wrapper || !this.wrapper.parentNode) return
    const errorMsg = this.wrapper.parentNode.querySelector('[data-searchable-select-error]')
    if (errorMsg) {
      errorMsg.remove()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.close()
    } else if (event.key === 'Enter') {
      event.preventDefault()
      const firstVisible = this.filteredOptions.find(opt => opt.style.display !== 'none')
      if (firstVisible) {
        firstVisible.click()
      }
    } else if (event.key === 'ArrowDown') {
      event.preventDefault()
      this.navigateOptions(1)
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      this.navigateOptions(-1)
    }
  }

  navigateOptions(direction) {
    const visibleOptions = this.filteredOptions.filter(opt => opt.style.display !== 'none')
    if (visibleOptions.length === 0) return

    const currentIndex = visibleOptions.findIndex(opt => opt.classList.contains('bg-blue-100'))
    let nextIndex = currentIndex + direction

    if (nextIndex < 0) nextIndex = visibleOptions.length - 1
    if (nextIndex >= visibleOptions.length) nextIndex = 0

    // Remove highlight from all
    visibleOptions.forEach(opt => {
      opt.classList.remove('bg-blue-100')
    })

    // Add highlight to selected
    visibleOptions[nextIndex].classList.add('bg-blue-100')
    visibleOptions[nextIndex].scrollIntoView({ block: 'nearest' })
  }
}

