<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  setup() {
    name: 'CardsMedia'
  }
})
</script>

<template>
  <!-- ----------------------------------------------------------------------------- -->
  <!-- Media -->
  <!-- ----------------------------------------------------------------------------- -->

  <div class="image-card">
    <img class="image-card" src="/src/assets/img/nefa-cc.webp" alt="" />
  </div>
</template>

<style scoped>
.image-card {
  min-height: 200px;
}
</style>
