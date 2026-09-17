<script setup>
import { ref, onMounted } from 'vue'
import SidebarView from './sidebar/SidebarView.vue'
import HeaderView from './header/HeaderView.vue'
const drawer = ref()
const innerW = window.innerWidth

onMounted(() => {
  if (innerW < 950) {
    drawer.value = !drawer.value
  }
})
</script>

<template>
  <v-app>
    <!--- Header -->
    <!-- ---------------------------------------------- -->
    <v-app-bar app elevation="1" class="pa-2">
     <v-btn
  class="hidden-md-and-up"
  icon
  @click="drawer = !drawer"
>
  <v-icon icon="mdi-menu" />
</v-btn>


      <img src="/src/assets/New Logo_with_Paratus.png" alt="Logo" class="w-24 h-24 mb-2 hidden md:flex" />

      <div class="logo pa-4 hidden md:flex items-center space-x-2">
  <p class="font-semibold text-lg">Paratus</p>
  <span class="text-sm text-gray-600">Powered By: Uppertech One Ltd</span>
</div>


      <v-spacer></v-spacer>
      <HeaderView />
    </v-app-bar>
    <!-- ---------------------------------------------- -->
    <!--- Sidebar -->
    <!-- ---------------------------------------------- -->
    <v-navigation-drawer
      left
      :permanent="$vuetify.display.mdAndUp"
      elevation="1"
      app
      :temporary="$vuetify.display.mdAndDown"
      v-model="drawer"
      expand-on-hover
      class="side-bar"
    >
      <SidebarView />
    </v-navigation-drawer>

    <!-- ---------------------------------------------- -->

    <!-- ---------------------------------------------- -->
    <!--- Page Wrapper -->
    <!-- ---------------------------------------------- -->
    <v-main class="mt-4 page-wrapper">
      <v-container fluid class="page-wrapper">
        <slot />
      </v-container>
    </v-main>
  </v-app>
</template>

<style scoped>
.side-bar {
  overflow: hidden !important;
}

.side-bar::-webkit-scrollbar {
  display: none; /* Chrome, Safari */
}

.page-wrapper {
  background-color: #f5f7f9;
}

.settings-icon {
  position: fixed;
  bottom: 16px;
  right: 16px;
  font-size: 36px;
  color: #121621;
  animation: rotate 5s linear infinite;
}

@keyframes rotate {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>
