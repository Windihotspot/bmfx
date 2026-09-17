import { onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

export function useAutoLogout(timeout = 15 * 60 * 1000) {
  const router = useRouter()
  const authStore = useAuthStore()
  let timeoutId: number | undefined

  const logout = () => {
    localStorage.removeItem('data')
    authStore.clearAuthData() // implement this method in your store
    router.push('/')
  }

  const resetTimer = () => {
    if (timeoutId) clearTimeout(timeoutId)
    timeoutId = window.setTimeout(logout, timeout)
  }

  const activityEvents = ['click', 'mousemove', 'keydown', 'scroll', 'touchstart']

  const setupListeners = () => {
    activityEvents.forEach(event =>
      window.addEventListener(event, resetTimer, { passive: true })
    )
  }

  const removeListeners = () => {
    activityEvents.forEach(event =>
      window.removeEventListener(event, resetTimer)
    )
    if (timeoutId) clearTimeout(timeoutId)
  }

  onMounted(() => {
    setupListeners()
    resetTimer()
  })

  onUnmounted(() => {
    removeListeners()
  })
}
