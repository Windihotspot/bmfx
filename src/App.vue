<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { RouterView } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const authReady = ref(false)

onMounted(async () => {
  try {
    await authStore.init()
  } finally {
    authReady.value = true
  }
})
</script>

<template>
  <main class="text-neutral-800">
    <RouterView />
  </main>
</template>

<style>
.custom-btn {
  background-color: #27bfa0;
}
</style>


