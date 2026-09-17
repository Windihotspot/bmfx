<script setup lang="ts">
import { ref, watch } from 'vue'
import confetti from 'canvas-confetti'
import { supabase } from '@/services/supabase'

const showConfirmDialog = ref(false)
const countdown = ref(15)
let timer: any = null

watch(showConfirmDialog, (val) => {
  if (val) {
    countdown.value = 15

    timer = setInterval(() => {
      countdown.value--

      if (countdown.value <= 0) {
        showConfirmDialog.value = false
        clearInterval(timer)
      }
    }, 1000)
  } else {
    clearInterval(timer)
  }
})

const firstName = ref('')
const email = ref('')

const formRef = ref()
const isValid = ref(false)
const loading = ref(false)
const success = ref(false)
const errorMessage = ref('')

const nameRules = [
  (v: string) => !!v || 'Your name is required',
  (v: string) => v.length >= 2 || 'Name must be at least 2 characters'
]

const emailRules = [
  (v: string) => !!v || 'Email is required',
  (v: string) => /.+@.+\..+/.test(v) || 'Enter a valid email'
]

const fireConfetti = () => {
  confetti({ particleCount: 120, spread: 70, origin: { y: 0.6 } })
}

const joinWaitlist = async () => {
  errorMessage.value = ''
  success.value = false

  const { valid } = await formRef.value.validate()
  if (!valid) return

  loading.value = true

  try {
    const { data, error } = await supabase.rpc('add_waitlist_lead', {
      p_first_name: firstName.value,
      p_email: email.value,
      p_source: 'landing_page'
    })

    if (error) throw error

    if (data.status === 'exists') {
      errorMessage.value = 'You are already on the waitlist.'
      return
    }

    success.value = true
    fireConfetti()
    showConfirmDialog.value = true
    firstName.value = ''
    email.value = ''

    formRef.value.resetValidation()
  } catch (err) {
    errorMessage.value = 'Something went wrong. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="bg-white/90 backdrop-blur-xl rounded-xl p-8 shadow-xl border border-white/40">
    <h2 class="text-2xl font-bold mb-6">Join the waitlist</h2>

    <v-form ref="formRef" v-model="isValid" @submit.prevent="joinWaitlist">
      <v-text-field
        v-model="firstName"
        label="First name"
        variant="outlined"
        :rules="nameRules"
        class="mb-4"
      />
      <v-text-field
        v-model="email"
        label="Email address"
        variant="outlined"
        :rules="emailRules"
        class="mb-6"
      />

      <div class="space-y-4 mb-6 text-sm">
        <div class="flex gap-3"><span>⚡</span><span>First access at launch</span></div>
        <div class="flex gap-3"><span>🚀</span><span>Priority onboarding</span></div>
        <div class="flex gap-3"><span>💸</span><span>37% early-access discount</span></div>
        <div class="flex gap-3"><span>📩</span><span>Free marketing emails & insights</span></div>
      </div>

      <v-btn
        block
        type="submit"
        :loading="loading"
        class="bg-purple-600 text-white font-semibold rounded-xl"
        height="52"
      >
        Join the Waitlist
      </v-btn>
    </v-form>

    <v-alert v-if="success" type="success" variant="tonal" class="mt-6">
      You're on the waitlist! Check your email.
    </v-alert>

    <v-dialog v-model="showConfirmDialog" max-width="520" persistent>
      <v-card class="rounded-2xl pa-6 text-center">
        <div class="text-3xl mb-2">🎉</div>

        <h3 class="text-xl font-bold mb-3">You’re In — One Final Step.</h3>

        <p class="text-gray-700 mb-4">
          We just sent you a confirmation email to secure your early-access spot.
          <br /><br />
          <strong>Confirming takes less than 9 seconds.</strong>
        </p>

        <p class="text-gray-700 mb-4">
          Until you confirm, your <strong>37% early-access discount</strong> and priority access to
          the Intelligent Conversion infrastructure are not locked in.
        </p>

        <p class="text-gray-700 mb-6">
          Open your inbox now and click the confirmation link. If you don’t see it, check your spam
          or promotions tab — we don’t want you missing your discounted access at launch.
        </p>

        <v-btn
        variant="text"
          block
          size="large"
          class="bg-purple-600 text-white font-semibold"
          @click="showConfirmDialog = false"
        >
        Go back 
        </v-btn>
      </v-card>
    </v-dialog>

    <v-alert v-if="errorMessage" type="error" variant="tonal" class="mt-6">
      {{ errorMessage }}
    </v-alert>
  </div>
</template>

<style scoped>
.v-btn {
    text-transform: none;
  background-color: #63376a;
}
.custom-btn {
  background-color: #63376a;
}
</style>
