<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import sidebarItems from '../sidebar/sidebarItem'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const currentPage = computed(() => {
  for (const group of sidebarItems) {
    const item = group.items.find((item) => {
      return (
        route.path === item.path ||
        route.path.startsWith(`${item.path}/`)
      )
    })

    if (item) return item.title
  }

  return 'Dashboard'
})

const userName = computed(() => {
  return (
    authStore.user?.name ||
    authStore.user?.email?.split('@')[0] ||
    'User'
  )
})

const userEmail = computed(() => {
  return authStore.user?.email || ''
})

const userRole = computed(() => {
  return authStore.user?.role || 'Member'
})

const organizationName = computed(() => {
  return authStore.organization?.name || 'Your Organization'
})

const userInitials = computed(() => {
  const name = userName.value.trim()

  if (!name) {
    return 'U'
  }

  const parts = name.split(/\s+/)

  if (parts.length === 1) {
    return parts[0].substring(0, 2).toUpperCase()
  }

  return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase()
})

const handleLogout = async () => {
  try {
    await authStore.logout()
    await router.push('/login')
  } catch (error) {
    console.error('Logout failed:', error)
  }
}
</script>

<template>
  <div class="flex w-full items-center justify-between gap-4">
    <!-- Page title -->
    <div class="min-w-0">
      

      <!-- <h1
        class="mt-0.5 truncate text-[15px] font-semibold text-gray-900"
      >
        {{ currentPage }}
      </h1> -->
    </div>

    <!-- Header actions -->
    <div class="flex items-center gap-2 sm:gap-3">
      <!-- Notifications -->
      <button
        class="relative flex h-10 w-10 items-center justify-center rounded-xl border border-gray-200 bg-white text-gray-500 transition hover:bg-gray-50"
      >
        <i class="fa-regular fa-bell text-sm"></i>

        <span
          class="absolute right-2 top-2 h-1.5 w-1.5 rounded-full bg-purple-600"
        ></span>
      </button>

      <!-- User menu -->
      <v-menu
        location="bottom end"
        :offset="8"
      >
        <template #activator="{ props }">
          <button
            v-bind="props"
            class="flex items-center gap-2 rounded-xl bg-white px-2 py-1.5 transition hover:bg-gray-50"
          >
            <!-- Avatar -->
            <div
              class="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-purple-600 to-violet-600 text-[11px] font-bold text-white"
            >
              {{ userInitials }}
            </div>

            <!-- User information -->
            <div class="hidden min-w-0 text-left md:block">
              <p
                class="max-w-[150px] truncate text-xs font-semibold text-gray-800"
              >
                {{ userName }}
              </p>

              <p
                class="max-w-[150px] truncate text-[10px] text-gray-400"
              >
                {{ organizationName }}
              </p>
            </div>

            <i
              class="fa-solid fa-chevron-down hidden text-[9px] text-gray-400 md:block"
            ></i>
          </button>
        </template>

        <!-- Dropdown -->
        <v-card
          min-width="280"
          class="overflow-hidden rounded-2xl border border-gray-100"
          elevation="8"
        >
          <!-- User header -->
          <div class="border-b border-gray-100 px-4 py-4">
            <div class="flex items-center gap-3">
              <!-- Avatar -->
              <div
                class="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-purple-600 to-violet-600 text-sm font-bold text-white"
              >
                {{ userInitials }}
              </div>

              <!-- Details -->
              <div class="min-w-0">
                <p
                  class="truncate text-sm font-semibold text-gray-900"
                >
                  {{ userName }}
                </p>

                <p
                  class="mt-0.5 truncate text-xs text-gray-400"
                >
                  {{ userEmail }}
                </p>

                <div class="mt-1 flex items-center gap-2">
                  <span
                    class="rounded-full bg-purple-50 px-2 py-0.5 text-[9px] font-semibold capitalize text-purple-600"
                  >
                    {{ userRole }}
                  </span>

                  <span
                    v-if="authStore.user?.is_owner"
                    class="rounded-full bg-green-50 px-2 py-0.5 text-[9px] font-semibold text-green-600"
                  >
                    Owner
                  </span>
                </div>
              </div>
            </div>

            <!-- Organization -->
            <div
              class="mt-4 flex items-center gap-3 rounded-xl bg-gray-50 px-3 py-3"
            >
              <div
                class="flex h-8 w-8 items-center justify-center rounded-lg bg-white text-purple-600 shadow-sm"
              >
                <i class="fa-solid fa-building text-xs"></i>
              </div>

              <div class="min-w-0">
                <p
                  class="text-[9px] font-semibold uppercase tracking-wider text-gray-400"
                >
                  Organization
                </p>

                <p
                  class="mt-0.5 truncate text-xs font-semibold text-gray-800"
                >
                  {{ organizationName }}
                </p>
              </div>
            </div>
          </div>

          <!-- Menu -->
          <div class="p-2">
            <v-list
              class="pa-0"
              density="comfortable"
            >
              <v-list-item
                to="/profile"
                rounded="lg"
              >
                <template #prepend>
                  <i
                    class="fa-regular fa-user mr-3 text-sm text-gray-400"
                  ></i>
                </template>

                <v-list-item-title class="text-sm">
                  My Profile
                </v-list-item-title>
              </v-list-item>

              <v-list-item
                to="/settings"
                rounded="lg"
              >
                <template #prepend>
                  <i
                    class="fa-solid fa-gear mr-3 text-sm text-gray-400"
                  ></i>
                </template>

                <v-list-item-title class="text-sm">
                  Settings
                </v-list-item-title>
              </v-list-item>

              <v-divider class="my-2"></v-divider>

              <v-list-item
                rounded="lg"
                class="logout-item"
                @click="handleLogout"
              >
                <template #prepend>
                  <i
                    class="fa-solid fa-arrow-right-from-bracket mr-3 text-sm"
                  ></i>
                </template>

                <v-list-item-title class="text-sm font-medium">
                  Logout
                </v-list-item-title>
              </v-list-item>
            </v-list>
          </div>
        </v-card>
      </v-menu>
    </div>
  </div>
</template>

<style scoped>
.logout-item {
  color: #dc2626;
}

.logout-item:hover {
  background: #fef2f2;
}
</style>