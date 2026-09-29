<script setup>
import { reactive, ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

const form = reactive({
  firstName: '',
  lastName: '',
  phone: '',
  email: '',
  password: '',
  confirmPassword: '',
})

const showPassword = ref(false)
const formError = ref('')
const emailSent = ref(false)

const passwordsMatch = computed(
  () => !form.confirmPassword || form.password === form.confirmPassword
)

function validate() {
  if (!form.firstName.trim() || !form.lastName.trim()) return 'Please enter your first and last name.'
  if (!/^\+?[0-9\s-]{7,15}$/.test(form.phone.trim())) return 'Please enter a valid phone number.'
  if (!/^\S+@\S+\.\S+$/.test(form.email.trim())) return 'Please enter a valid email address.'
  if (form.password.length < 8) return 'Password must be at least 8 characters.'
  if (form.password !== form.confirmPassword) return 'Passwords do not match.'
  return ''
}

async function handleSubmit() {
  formError.value = validate()
  if (formError.value) return

  const result = await auth.signUp({
    firstName: form.firstName.trim(),
    lastName: form.lastName.trim(),
    phone: form.phone.trim(),
    email: form.email.trim(),
    password: form.password,
  })

  if (!result.success) return

  if (result.needsEmailConfirmation) {
    emailSent.value = true
  } else {
    router.push('/dashboard') // change to your route
  }
}

const inputClass =
  'w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-800 placeholder-slate-400 outline-none transition focus:border-fuchsia-400 focus:bg-white focus:ring-4 focus:ring-fuchsia-100'
</script>

<template>
  <div class="relative min-h-screen overflow-hidden bg-[#f5f6fa] text-slate-800 antialiased selection:bg-fuchsia-100">
    <!-- ambient backdrop -->
    <div class="pointer-events-none absolute inset-0 -z-0">
      <div class="absolute right-0 top-[-10%] h-[600px] w-[600px] rounded-full bg-fuchsia-100/60 blur-[140px]"></div>
      <div class="absolute left-0 bottom-0 h-[400px] w-[400px] rounded-full bg-violet-100/60 blur-[120px]"></div>
    </div>

    <div class="relative z-10 mx-auto flex min-h-screen max-w-md flex-col justify-center px-6 py-12">
      <!-- logo -->
      <a href="/" class="mb-8 flex items-center justify-center gap-2">
        <span class="flex h-9 w-9 items-center justify-center rounded-lg bg-gradient-to-br from-fuchsia-500 to-violet-600">
          <i class="fa-solid fa-bolt text-sm text-white"></i>
        </span>
        <span class="text-lg font-semibold tracking-tight text-slate-900">BMFX</span>
      </a>

      <!-- success state -->
      <div v-if="emailSent" class="rounded-3xl border border-slate-100 bg-white p-8 text-center shadow-sm">
        <span class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-emerald-50">
          <v-icon icon="mdi-email-check-outline" size="24" class="text-emerald-500" />
        </span>
        <h2 class="mt-5 text-2xl font-bold tracking-tight text-slate-900">Check your email</h2>
        <p class="mt-2 text-sm text-slate-500">
          We sent a confirmation link to
          <span class="font-medium text-slate-700">{{ form.email }}</span>.
          Click it to activate your account.
        </p>
        <router-link
          to="/login"
          class="mt-6 inline-flex items-center gap-1.5 rounded-full bg-gradient-to-r from-fuchsia-500 to-rose-400 px-6 py-3 text-sm font-medium text-white shadow-md shadow-fuchsia-500/25 transition hover:brightness-110"
        >
          Go to Sign In
          <v-icon icon="mdi-arrow-right" size="16" />
        </router-link>
      </div>

      <!-- form -->
      <div v-else class="rounded-3xl border border-slate-100 bg-white p-8 shadow-sm">
        <div class="text-center">
          <span class="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-1.5 text-xs text-slate-500 shadow-sm">
            <v-icon icon="mdi-chevron-up" size="14" class="text-fuchsia-500" />
            Create your free account
          </span>
          <h1 class="mt-5 text-3xl font-bold tracking-tight text-slate-900">Join BMFX</h1>
          <p class="mt-2 text-sm text-slate-500">Start trading in a few minutes.</p>
        </div>

        <form class="mt-8 space-y-4" @submit.prevent="handleSubmit" novalidate>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="mb-1.5 block text-xs text-slate-400">First name</label>
              <input v-model="form.firstName" type="text" autocomplete="given-name" placeholder="John" :class="inputClass" />
            </div>
            <div>
              <label class="mb-1.5 block text-xs text-slate-400">Last name</label>
              <input v-model="form.lastName" type="text" autocomplete="family-name" placeholder="Doe" :class="inputClass" />
            </div>
          </div>

          <div>
            <label class="mb-1.5 block text-xs text-slate-400">Phone number</label>
            <input v-model="form.phone" type="tel" autocomplete="tel" placeholder="+234 800 000 0000" :class="inputClass" />
          </div>

          <div>
            <label class="mb-1.5 block text-xs text-slate-400">Email</label>
            <input v-model="form.email" type="email" autocomplete="email" placeholder="you@example.com" :class="inputClass" />
          </div>

          <div>
            <label class="mb-1.5 block text-xs text-slate-400">Password</label>
            <div class="relative">
              <input
                v-model="form.password"
                :type="showPassword ? 'text' : 'password'"
                autocomplete="new-password"
                placeholder="At least 8 characters"
                :class="[inputClass, 'pr-11']"
              />
              <button
                type="button"
                class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-300 transition hover:text-slate-500"
                @click="showPassword = !showPassword"
              >
                <v-icon :icon="showPassword ? 'mdi-eye-off-outline' : 'mdi-eye-outline'" size="18" />
              </button>
            </div>
          </div>

          <div>
            <label class="mb-1.5 block text-xs text-slate-400">Confirm password</label>
            <input
              v-model="form.confirmPassword"
              :type="showPassword ? 'text' : 'password'"
              autocomplete="new-password"
              placeholder="Re-enter your password"
              :class="[inputClass, !passwordsMatch && 'border-rose-300 focus:border-rose-400 focus:ring-rose-100']"
            />
            <p v-if="!passwordsMatch" class="mt-1.5 text-[11px] text-rose-500">Passwords do not match.</p>
          </div>

          <p
            v-if="formError || auth.error"
            class="rounded-2xl bg-rose-50 px-4 py-2.5 text-xs text-rose-500"
          >
            {{ formError || auth.error }}
          </p>

          <button
            type="submit"
            :disabled="auth.loading"
            class="flex w-full items-center justify-center gap-2 rounded-full bg-gradient-to-r from-fuchsia-500 to-rose-400 px-6 py-3 text-sm font-medium text-white shadow-md shadow-fuchsia-500/25 transition hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-60"
          >
            <v-progress-circular v-if="auth.loading" indeterminate size="16" width="2" />
            <template v-else>
              Create Account
              <v-icon icon="mdi-arrow-right" size="16" />
            </template>
          </button>
        </form>

        <p class="mt-6 text-center text-xs text-slate-500">
          Already have an account?
          <router-link to="/login" class="font-medium text-fuchsia-500 hover:text-fuchsia-600">Sign In</router-link>
        </p>
      </div>
    </div>
  </div>
</template>