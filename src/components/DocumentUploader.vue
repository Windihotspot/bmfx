<template>
  <div class="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center relative hover:border-blue-500 transition-all">
    <label
      class="flex flex-col items-center justify-center cursor-pointer h-full"
      @dragover.prevent
      @drop.prevent="handleDrop"
    >
      <v-icon color="primary" size="36">mdi-cloud-upload</v-icon>
      <p class="text-sm text-gray-600 mt-2">Upload File</p>
      <input
        type="file"
        class="hidden"
        @change="handleFileChange"
        accept=".pdf,.jpg,.jpeg,.png,.doc,.docx"
      />
    </label>
    <p v-if="modelValue" class="mt-4 text-xs text-gray-500">
      {{ modelValue.name }}
    </p>
    <p class="absolute top-2 left-3 text-sm font-medium text-gray-800">{{ label }}</p>
  </div>
</template>

<script setup>
import { defineProps, defineEmits } from 'vue'

const props = defineProps({
  label: String,
  modelValue: File
})

const emit = defineEmits(['update:modelValue'])

const handleFileChange = (e) => {
  const file = e.target.files[0]
  if (file) emit('update:modelValue', file)
}

const handleDrop = (e) => {
  const file = e.dataTransfer.files[0]
  if (file) emit('update:modelValue', file)
}
</script>
