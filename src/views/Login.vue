<script setup>
import { reactive, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()

const form = reactive({ email: '', password: '' })
const showPassword = ref(false)
const formError = ref('')

async function handleSubmit() {
  formError.value = ''
  auth.error = null

  if (!/^\S+@\S+\.\S+$/.test(form.email.trim())) {
    formError.value = 'Please enter a valid email address.'
    return
  }
  if (!form.password) {
    formError.value = 'Please enter your password.'
    return
  }

  const result = await auth.signIn({
    email: form.email.trim(),
    password: form.password,
  })

  if (result.success) {
    // go back to the page they tried to open, else the dashboard
    router.push(route.query.redirect || '/dashboard')
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

      <div class="rounded-3xl border border-slate-100 bg-white p-8 shadow-sm">
        <div class="text-center">
          <span class="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-1.5 text-xs text-slate-500 shadow-sm">
            <v-icon icon="mdi-chevron-up" size="14" class="text-fuchsia-500" />
            Welcome back
          </span>
          <h1 class="mt-5 text-3xl font-bold tracking-tight text-slate-900">Sign in to BMFX</h1>
          <p class="mt-2 text-sm text-slate-500">Access your wallet and portfolio.</p>
        </div>

        <form class="mt-8 space-y-4" @submit.prevent="handleSubmit" novalidate>
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
                autocomplete="current-password"
                placeholder="Your password"
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
              Sign In
              <v-icon icon="mdi-arrow-right" size="16" />
            </template>
          </button>
        </form>

        <p class="mt-6 text-center text-xs text-slate-500">
          New to BMFX?
          <router-link to="/register" class="font-medium text-fuchsia-500 hover:text-fuchsia-600">Create an account</router-link>
        </p>
      </div>
    </div>
  </div>
</template>