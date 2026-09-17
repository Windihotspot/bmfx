<!-- ConfettiSuccessModal.vue -->
<template>
  <div v-if="visible" class="fixed inset-0 z-50 flex items-center justify-center">
    <div class="bg-white p-8 rounded-lg shadow-xl text-center">
      <i class="fas fa-check-circle text-green-500 text-6xl mb-4"></i>
      <h2 class="text-xl font-bold mb-2">Success!</h2>
      <p class="text-gray-600">Your bank statement has been added successfully.</p>

      <v-btn color="#1f5aa3" @click="$emit('close')" class="custom-btn text-white w-full m-4">
        Return Home
      </v-btn>
    </div>
  </div>
</template>

<script setup>
defineProps({ visible: Boolean })
</script>

<style scoped>
.custom-btn {
  background-color: #1f5aa3;
  text-transform: none;
}
</style>
