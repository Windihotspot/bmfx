import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/services/supabase.js'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null) // supabase user object
  const merchant = ref(null) // merchant details
  const token = ref(null) // optional JWT or session token

  const facilities = ref([]) // merchant facilities
  const selectedFacility = ref(null)

  // Load from localStorage on init
  const init = () => {
    const storedUser = localStorage.getItem('user')
    const storedMerchant = localStorage.getItem('merchant')
    const storedToken = localStorage.getItem('token')
    const storedFacilities = localStorage.getItem('facilities')
    const storedSelectedFacility = localStorage.getItem('selectedFacility')

    if (storedUser) user.value = JSON.parse(storedUser)
    if (storedMerchant) merchant.value = JSON.parse(storedMerchant)
    if (storedToken) token.value = storedToken
    if (storedFacilities) facilities.value = JSON.parse(storedFacilities)
    if (storedSelectedFacility) selectedFacility.value = JSON.parse(storedSelectedFacility)
  }

  const setAuth = (u, m, t = null) => {
    user.value = u
    merchant.value = m
    token.value = t

    localStorage.setItem('user', JSON.stringify(u))
    localStorage.setItem('merchant', JSON.stringify(m))
    if (t) localStorage.setItem('token', t)
  }

  const setSelectedFacility = (facilityId) => {
    const found = facilities.value.find((f) => f.id === facilityId) || null
    selectedFacility.value = found
    if (found) {
      localStorage.setItem('selectedFacility', JSON.stringify(found))
    } else {
      localStorage.removeItem('selectedFacility')
    }
  }

  const setFacilities = (list) => {
    facilities.value = list || []
    localStorage.setItem('facilities', JSON.stringify(list || []))

    // Preserve selected if still in the new list
    if (selectedFacility.value) {
      const stillExists = facilities.value.find((f) => f.id === selectedFacility.value.id)
      if (stillExists) {
        setSelectedFacility(stillExists.id)
        return
      }
    }

    // Otherwise fallback to first one
    if (list?.length > 0) {
      setSelectedFacility(list[0].id)
    } else {
      setSelectedFacility(null)
    }
  }

  const fetchFacilities = async () => {
    const { data, error } = await supabase.rpc('get_merchant_facilities', {
      p_merchant_id: merchant.value.id
    })
    console.log('merchant facillities:', data)
    if (error) throw error
    setFacilities(data || [])
  }

  const logout = () => {
    user.value = null
    merchant.value = null
    token.value = null
    facilities.value = []
    selectedFacility.value = null

    localStorage.removeItem('user')
    localStorage.removeItem('merchant')
    localStorage.removeItem('token')
    localStorage.removeItem('facilities')
    localStorage.removeItem('selectedFacility')
  }
  return {
    user,
    merchant,
    token,
    facilities,
    selectedFacility,
    setAuth,
    setFacilities,
    setSelectedFacility,
    logout,
    init,
    fetchFacilities
  }
})
