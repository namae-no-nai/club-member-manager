import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["loader", "error", "errorMessage", "noResults", "results", "resultsList"]

    connect() {
        this.performSearch()
    }

    async performSearch() {
        // Show loader, hide other states
        this.showLoader()

        try {
            const response = await fetch('/fingerprint_verifications/search', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
                }
            })

            const data = await response.json()

            if (!response.ok || !data.success) {
                this.showError(data.error || 'Erro ao processar a solicitação')
                return
            }

            if (data.partners && data.partners.length > 0) {
                this.showResults(data.partners)
            } else {
                this.showNoResults()
            }
        } catch (error) {
            console.error('Fingerprint search error:', error)
            this.showError('Erro ao conectar com o servidor. Verifique se o leitor biométrico está conectado.')
        }
    }

    showLoader() {
        this.loaderTarget.classList.remove('hidden')
        this.errorTarget.classList.add('hidden')
        this.noResultsTarget.classList.add('hidden')
        this.resultsTarget.classList.add('hidden')
    }

    showError(message) {
        this.errorMessageTarget.textContent = message
        this.loaderTarget.classList.add('hidden')
        this.errorTarget.classList.remove('hidden')
        this.noResultsTarget.classList.add('hidden')
        this.resultsTarget.classList.add('hidden')
    }

    showNoResults() {
        this.loaderTarget.classList.add('hidden')
        this.errorTarget.classList.add('hidden')
        this.noResultsTarget.classList.remove('hidden')
        this.resultsTarget.classList.add('hidden')
    }

    showResults(partners) {
        this.loaderTarget.classList.add('hidden')
        this.errorTarget.classList.add('hidden')
        this.noResultsTarget.classList.add('hidden')
        this.resultsTarget.classList.remove('hidden')

        // Clear previous results securely
        while (this.resultsListTarget.firstChild) {
            this.resultsListTarget.removeChild(this.resultsListTarget.firstChild)
        }

        // Sort partners by score (highest first)
        const sortedPartners = partners.sort((a, b) => b.score - a.score)

        // Create result cards for each partner
        sortedPartners.forEach((partner, index) => {
            const card = this.createPartnerCard(partner, index + 1)
            this.resultsListTarget.appendChild(card)
        })
    }

    createPartnerCard(partner, rank) {
        const card = document.createElement('div')
        card.className = 'bg-white border border-gray-300 rounded-md p-4 hover:border-red-600 transition duration-200 shadow-sm'

        const scorePercentage = Math.round(partner.score)
        const scoreColor = scorePercentage >= 80 ? 'text-green-600' : scorePercentage >= 60 ? 'text-yellow-600' : 'text-orange-600'

        // Header section
        const headerDiv = document.createElement('div')
        headerDiv.className = 'flex justify-between items-start mb-4'

        const headerContent = document.createElement('div')
        headerContent.className = 'flex-1'

        const badgeContainer = document.createElement('div')
        badgeContainer.className = 'flex items-center gap-2 mb-2'

        const rankBadge = document.createElement('span')
        rankBadge.className = 'inline-block bg-red-600 text-white text-sm font-bold px-3 py-1 rounded-full'
        rankBadge.textContent = `#${rank}`

        const scoreBadge = document.createElement('span')
        scoreBadge.className = `text-sm ${scoreColor} font-semibold`
        scoreBadge.textContent = `Score ${scorePercentage}`

        badgeContainer.appendChild(rankBadge)
        badgeContainer.appendChild(scoreBadge)

        const nameHeading = document.createElement('h3')
        nameHeading.className = 'text-lg font-bold text-gray-800'
        nameHeading.textContent = partner.name

        headerContent.appendChild(badgeContainer)
        headerContent.appendChild(nameHeading)
        headerDiv.appendChild(headerContent)

        // Details grid
        const detailsGrid = document.createElement('div')
        detailsGrid.className = 'grid grid-cols-2 gap-4 text-sm'

        // CPF field
        const cpfDiv = document.createElement('div')
        const cpfLabel = document.createElement('span')
        cpfLabel.className = 'text-sm text-gray-700 font-medium'
        cpfLabel.textContent = 'CPF: '
        const cpfValue = document.createElement('span')
        cpfValue.className = 'text-sm text-gray-900'
        cpfValue.textContent = this.formatCPF(partner.cpf)
        cpfDiv.appendChild(cpfLabel)
        cpfDiv.appendChild(cpfValue)

        // CR field
        const crDiv = document.createElement('div')
        const crLabel = document.createElement('span')
        crLabel.className = 'text-sm text-gray-700 font-medium'
        crLabel.textContent = 'CR: '
        const crValue = document.createElement('span')
        crValue.className = 'text-sm text-gray-900'
        crValue.textContent = partner.registry_certificate || 'N/A'
        crDiv.appendChild(crLabel)
        crDiv.appendChild(crValue)

        // Filiation number field
        const filiationDiv = document.createElement('div')
        filiationDiv.className = 'col-span-2'
        const filiationLabel = document.createElement('span')
        filiationLabel.className = 'text-sm text-gray-700 font-medium'
        filiationLabel.textContent = 'Número de Filiação: '
        const filiationValue = document.createElement('span')
        filiationValue.className = 'text-sm text-gray-900'
        filiationValue.textContent = partner.filiation_number || 'N/A'
        filiationDiv.appendChild(filiationLabel)
        filiationDiv.appendChild(filiationValue)

        detailsGrid.appendChild(cpfDiv)
        detailsGrid.appendChild(crDiv)
        detailsGrid.appendChild(filiationDiv)

        // Action section
        const actionDiv = document.createElement('div')
        actionDiv.className = 'mt-4 pt-4 border-t border-gray-200'

        const detailsLink = document.createElement('a')
        detailsLink.href = `/partners/${partner.id}`
        detailsLink.className = 'inline-block w-full text-center px-4 py-2 bg-red-600 text-white rounded-md shadow-md hover:bg-red-700 transition'
        detailsLink.textContent = 'Ver Detalhes do Sócio'

        actionDiv.appendChild(detailsLink)

        // Assemble the card
        card.appendChild(headerDiv)
        card.appendChild(detailsGrid)
        card.appendChild(actionDiv)

        return card
    }

    formatCPF(cpf) {
        if (!cpf) return 'N/A'
        // Format CPF as XXX.XXX.XXX-XX
        const cleaned = cpf.replace(/\D/g, '')
        return cleaned.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4')
    }

    retry() {
        this.performSearch()
    }
}

