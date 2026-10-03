import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/services/supabase' // adjust to wherever your client file lives

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const session = ref(null)
  const loading = ref(false)
  const error = ref(null)

  async function signUp({ firstName, lastName, phone, email, password }) {
    loading.value = true
    error.value = null

    const { data, error: signUpError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        // picked up by the DB trigger to create the profiles row
        data: {
          first_name: firstName,
          last_name: lastName,
          phone
        }
      }
    })

    loading.value = false

    if (signUpError) {
      error.value = signUpError.message
      return { success: false }
    }

    user.value = data.user
    session.value = data.session

    // If email confirmation is ON in Supabase, session is null until they verify.
    return { success: true, needsEmailConfirmation: !data.session }
  }

  async function signIn({ email, password }) {
    loading.value = true
    error.value = null

    const { data, error: signInError } = await supabase.auth.signInWithPassword({
      email,
      password
    })

    loading.value = false

    if (signInError) {
      error.value =
        signInError.message === 'Email not confirmed'
          ? 'Please confirm your email first. Check your inbox for the link.'
          : signInError.message
      return { success: false }
    }

    user.value = data.user
    console.log('user:', user.value)
    session.value = data.session
    return { success: true }
  }

  async function logOut() {
    await supabase.auth.signOut()
    user.value = null
    session.value = null
  }

  // Call once in main.js / App.vue to keep state in sync
  async function init() {
    const { data } = await supabase.auth.getSession()
    session.value = data.session
    user.value = data.session?.user ?? null

    supabase.auth.onAuthStateChange((_event, newSession) => {
      session.value = newSession
      user.value = newSession?.user ?? null
    })
  }

  return { user, session, loading, error, signUp, signIn, logOut, init }
})
