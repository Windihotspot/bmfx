import Dashboard from '@/views/Dashboard.vue'
import LandingPage from '@/views/LandingPage.vue'
import Portfolio from '@/views/Portfolio.vue'
import { createRouter, createWebHistory } from 'vue-router'


const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: LandingPage
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: Dashboard
    },
    {
      path: '/portfolio',
      name: 'portfolio',
      component: Portfolio
    }
    
  ]
})

export default router
