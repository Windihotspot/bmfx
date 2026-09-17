// /composables/useFormattedField.js
import { computed } from 'vue'

export function useFormattedFields(targetRef, key, options = { currency: false }) {
  const formatCurrency = (value) => {
    return new Intl.NumberFormat('en-NG', {
      style: 'currency',
      currency: 'NGN',
      minimumFractionDigits: 0
    }).format(value || 0)
  }

  return computed({
    get() {
      const value = targetRef.value[key]
      if (value === null || value === undefined) return ''
      return options.currency ? formatCurrency(value) : value.toString()
    },
    set(val) {
      const input = String(val || '')
      const numeric = Number(
        options.currency ? input.replace(/[₦, ]/g, '') : input.replace(/[^0-9]/g, '')
      )
      targetRef.value[key] = input.trim() === '' ? null : isNaN(numeric) ? 0 : numeric
    }
  })
}


