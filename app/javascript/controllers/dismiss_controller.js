import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    articleId: Number,
    articleTitle: String
  }
  
  static targets = ["article"]
  
  connect() {
    this.lastDismissedId = null
    this.setupKeyboardShortcuts()
  }
  
  disconnect() {
    this.clearKeyboardShortcuts()
  }
  
  dismiss(event) {
    event.preventDefault()
    
    const articleCard = this.element.closest('.article-card')
    if (!articleCard) return
    
    const articleId = this.articleIdValue
    const articleTitle = this.articleTitleValue
    
    this.lastDismissedId = articleId
    
    articleCard.style.opacity = '0.5'
    articleCard.style.pointerEvents = 'none'
    
    const undoClickHandler = (e) => {
      e.preventDefault()
      e.stopPropagation()
      this.undoDismiss(articleId, articleCard, undoClickHandler)
    }
    articleCard.addEventListener('click', undoClickHandler)
    articleCard.dataset.undoHandler = 'true'
    
    fetch(`/articles/${articleId}/dismiss`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    }).then(response => {
      if (response.ok) {
        return response.json()
      }
      throw new Error('Network response was not ok')
    }).then(data => {
      this.showUndoToast(articleId, articleTitle, articleCard, undoClickHandler)
    }).catch(error => {
      console.error('Error dismissing article:', error)
      articleCard.style.opacity = '1'
      articleCard.style.pointerEvents = 'auto'
      articleCard.removeEventListener('click', undoClickHandler)
      delete articleCard.dataset.undoHandler
    })
  }
  
  showUndoToast(articleId, articleTitle, articleCard, undoClickHandler) {
    const existingToast = document.querySelector('.dismiss-toast')
    if (existingToast) {
      existingToast.remove()
    }
    
    const toast = document.createElement('div')
    toast.className = 'dismiss-toast fixed top-4 right-4 bg-dark-800 border border-primary-500/30 rounded-xl p-4 shadow-2xl z-50 max-w-sm animate-slide-in'
    
    let timeLeft = 15
    
    const updateToastContent = () => {
      toast.innerHTML = `
        <div class="flex items-center justify-between">
          <div class="flex-1 mr-4">
            <div class="text-primary-300 font-medium text-sm mb-1">Article dismissed</div>
            <div class="text-gray-400 text-xs">${articleTitle}</div>
          </div>
          <div class="flex items-center space-x-2">
            <button class="undo-btn px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white text-sm font-medium rounded-lg transition-all duration-200 hover:scale-105" 
                    onclick="window.dismissController.undoDismissFromToast(${articleId})">
              UNDO
            </button>
          </div>
        </div>
        <div class="mt-3 text-xs text-gray-500 flex items-center justify-between">
          <span>Ctrl+Z to undo</span>
          <span class="countdown">${timeLeft}s remaining</span>
        </div>
        <div class="mt-2 bg-dark-700 rounded-full h-1 overflow-hidden">
          <div class="countdown-bar bg-primary-500 h-full transition-all duration-1000" style="width: ${(timeLeft/15)*100}%"></div>
        </div>
      `
    }
    
    updateToastContent()
    document.body.appendChild(toast)
    
    window.dismissController = this
    this.currentToast = toast
    this.currentArticleCard = articleCard
    this.currentUndoHandler = undoClickHandler
    
    const countdownInterval = setInterval(() => {
      timeLeft--
      updateToastContent()
      
      if (timeLeft <= 0) {
        clearInterval(countdownInterval)
        this.finalizeDismiss(articleCard, undoClickHandler)
        toast.remove()
        this.currentToast = null
      }
    }, 1000)
    
    this.currentCountdown = countdownInterval
  }
  
  undoDismissFromToast(articleId) {
    this.undoDismiss(articleId, this.currentArticleCard, this.currentUndoHandler)
  }
  
  undoDismiss(articleId, articleCard, undoClickHandler) {
    if (this.currentCountdown) {
      clearInterval(this.currentCountdown)
    }
    
    if (this.currentToast) {
      this.currentToast.remove()
      this.currentToast = null
    }
    
    articleCard.style.opacity = '1'
    articleCard.style.pointerEvents = 'auto'
    articleCard.removeEventListener('click', undoClickHandler)
    delete articleCard.dataset.undoHandler
    
    fetch(`/articles/${articleId}/undismiss`, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    }).then(response => {
      if (response.ok) {
        return response.json()
      }
      throw new Error('Network response was not ok')
    }).then(data => {
      console.log('Article restored successfully')
    }).catch(error => {
      console.error('Error restoring article:', error)
    })
  }
  
  finalizeDismiss(articleCard, undoClickHandler) {
    articleCard.style.transition = 'all 0.5s ease-out'
    articleCard.style.transform = 'translateX(-100%)'
    articleCard.style.opacity = '0'
    
    setTimeout(() => {
      articleCard.remove()
    }, 500)
    
    articleCard.removeEventListener('click', undoClickHandler)
  }
  
  setupKeyboardShortcuts() {
    this.keyHandler = (event) => {
      if (event.ctrlKey && event.key === 'z' && this.lastDismissedId && this.currentToast) {
        event.preventDefault()
        this.undoDismiss(this.lastDismissedId, this.currentArticleCard, this.currentUndoHandler)
      }
    }
    document.addEventListener('keydown', this.keyHandler)
  }
  
  clearKeyboardShortcuts() {
    if (this.keyHandler) {
      document.removeEventListener('keydown', this.keyHandler)
    }
  }
}
