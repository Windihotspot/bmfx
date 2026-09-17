<template>
  <button
    type="button"
    class="btn rounded font-normal leading-4 ripple"
    :class="[
      props.block ? 'block w-full' : 'inline-block',
      props.sm ? 'sm' : '',
      props.xl ? 'xl' : '',
      props.rounded ? 'rounded-full' : '',
      props.icon ? 'p-2 flex items-center justify-center' : 'py-2 px-5'
    ]"
  >
    <slot />
  </button>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  props: {
    block: Boolean,
    sm: Boolean,
    xl: Boolean,
    icon: Boolean,
    rounded: Boolean,
    icon: Boolean
  },
  setup() {}
})
</script>
