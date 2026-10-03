<script setup>
import { computed } from 'vue'
import sidebarItems from './sidebarItem'
import { useAuthStore } from '@/stores/auth'

defineEmits(['navigate'])

const authStore = useAuthStore()

const userRole = computed(() => {
  return authStore.user?.role?.toLowerCase() || ''
})

const visibleSidebarItems = computed(() => {
  return sidebarItems.filter((group) => {
    return group.roles?.includes(userRole.value)
  })
})
</script>

<template>
  <div class="flex h-full flex-col bg-white">

    <!-- Logo -->
    <div class="flex h-[76px] shrink-0 items-center border-b border-purple-50 px-6">
      <RouterLink to="/dashboard" class="flex items-center gap-3">
        
      </RouterLink>
    </div>

    <!-- Navigation -->
    <nav class="sidebar-scroll flex-1 overflow-y-auto px-4 py-4">
      <div
        v-for="group in visibleSidebarItems"
        :key="group.section"
        class="mb-5"
      >
        <p
          class="mb-2 px-3 text-[10px] font-semibold uppercase tracking-[0.16em] text-gray-400"
        >
          {{ group.section }}
        </p>

        <div class="space-y-1">
          <RouterLink
            v-for="item in group.items"
            :key="item.path"
            :to="item.path"
            class="group flex items-center gap-3 rounded-md px-3 py-2.5 transition-all duration-150"
            active-class="sidebar-active"
            exact-active-class="sidebar-active"
            @click="$emit('navigate')"
          >
            <div
              class="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-gray-400 transition-all group-hover:text-purple-600"
            >
              <i :class="item.icon" class="text-sm"></i>
            </div>

            <span
              class="min-w-0 flex-1 truncate text-[13px] font-medium text-gray-600 transition-colors group-hover:text-gray-900"
            >
              {{ item.title }}
            </span>

            <span
              v-if="item.badge"
              class="rounded-full bg-purple-100 px-2 py-0.5 text-[8px] font-bold text-purple-600"
            >
              {{ item.badge }}
            </span>
          </RouterLink>
        </div>
      </div>
    </nav>


  </div>
</template>

<style scoped>
.sidebar-scroll {
  scrollbar-width: none;
}

.sidebar-scroll::-webkit-scrollbar {
  display: none;
}

.sidebar-active {
  background: #f5f3ff;
}

.sidebar-active div {
  background: white;
  color: #7c3aed;
  box-shadow: 0 2px 8px rgba(124, 58, 237, 0.08);
}

.sidebar-active span {
  color: #6d28d9;
  font-weight: 600;
}
</style>