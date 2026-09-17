<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  setup() {
    name: 'CardProps'
  }
})
</script>

<template>
  <!-- ----------------------------------------------------------------------------- -->
  <!-- Props -->
  <!-- ----------------------------------------------------------------------------- -->
  <v-card title="This is a title" subtitle="This is a subtitle" text="This is content"></v-card>
</template>
