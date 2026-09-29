import Dashboard from '@/views/Dashboard.vue'
import LandingPage from '@/views/LandingPage.vue'
import Login from '@/views/Login.vue'
import Portfolio from '@/views/Portfolio.vue'
import SignupPage from '@/views/SignupPage.vue'
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
      path: '/register',
      name: 'register',
      component: SignupPage
    },
    {
      path: '/login',
      name: 'login',
      component: Login
    },
   
  ]
})

export default router
