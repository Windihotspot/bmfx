// composables/usePhoneNumber.js
import { ref, watch } from 'vue'

export function usePhoneNumber(initialValue = '') {
  const phone = ref(initialValue)

  // Ensure prefix 234 and max 13 digits
  watch(phone, (newVal, oldVal) => {
    if (!newVal) return

    // Remove non-numeric characters
    let cleaned = newVal.replace(/\D/g, '')

    // Add 234 prefix if missing
    if (!cleaned.startsWith('234')) {
      cleaned = '234' + cleaned.replace(/^0+/, '')
    }

    // Limit to 13 digits
    if (cleaned.length > 13) {
      cleaned = cleaned.slice(0, 13)
    }

    // Only update if changed to avoid infinite loop
    if (cleaned !== newVal) {
      phone.value = cleaned
    }
  })

  // Validation function
  const validate = () => /^234\d{10}$/.test(phone.value)

  return { phone, validate }
}