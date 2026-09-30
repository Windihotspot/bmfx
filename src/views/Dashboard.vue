<script setup>
import { ref } from 'vue'

const activeNav = ref('Home')

const sidebarNav = [
  { label: 'Home', icon: 'mdi-view-dashboard-outline' },
  { label: 'Wallet', icon: 'mdi-wallet-outline', badge: 7 },
  { label: 'Orders', icon: 'mdi-swap-horizontal-bold', badge: 10 },
  { label: 'Activity', icon: 'mdi-pulse' },
  { label: 'Watchlist', icon: 'mdi-star-outline' },
  { label: 'Markets', icon: 'mdi-chart-box-outline' },
  { label: 'Settings', icon: 'mdi-cog-outline' },
]

const user = ref({
  name: 'Alex Carter',
  role: 'Premium Trader',
  initials: 'AC',
})

const shortcuts = [
  { label: 'Markets', icon: 'mdi-chart-line' },
  { label: 'Invest', icon: 'mdi-piggy-bank-outline' },
  { label: 'Convert', icon: 'mdi-swap-horizontal' },
  { label: 'Alerts', icon: 'mdi-bell-outline' },
  { label: 'News', icon: 'mdi-newspaper-variant-outline' },
]

const wallet = ref({
  total: '$15.00',
  changePercent: -1.7,
  deposits: '4,240',
  withdrawals: '1,180',
  btc: '0.42',
  sparkline: '0,28 12,20 24,24 36,12 48,16 60,6 72,10 84,2',
})

const referral = ref({
  title: 'Invite a friend, earn rewards',
  subtitle: 'Share your referral link and both of you get $10 in trading credit.',
  avatarSeeds: ['J', 'M', 'R'],
})

const statFilter = ref('Monthly')
const statSeries = ref({
  months: ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'],
  buyPoint: '$21,720',
  sellPoint: '$19,730',
  buyPath: '0,70 40,50 80,60 120,20 160,35 200,10 240,30 280,15',
  sellPath: '0,40 40,55 80,35 120,60 160,45 200,65 240,40 280,55',
})

const newsletter = ref({
  email: '',
})
</script>

<template>
  <div class="flex min-h-screen bg-[#f5f6fa] text-slate-800 antialiased">

    <!-- ============ SIDEBAR ============ -->
    <aside class="hidden w-64 flex-col justify-between border-r border-slate-100 bg-white px-5 py-6 lg:flex">
      <div>
        <a href="#" class="mb-8 flex items-center gap-2 px-2">
          <span class="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-fuchsia-500 to-violet-600">
            <i class="fa-solid fa-bolt text-xs text-white"></i>
          </span>
          <span class="text-base font-semibold tracking-tight text-slate-900">BMFX</span>
        </a>

        <nav class="space-y-1">
          <button
            v-for="item in sidebarNav"
            :key="item.label"
            @click="activeNav = item.label"
            class="flex w-full items-center justify-between rounded-xl px-3 py-2.5 text-sm transition"
            :class="activeNav === item.label
              ? 'bg-slate-900 text-white'
              : 'text-slate-500 hover:bg-slate-50 hover:text-slate-900'"
          >
            <span class="flex items-center gap-3">
              <v-icon :icon="item.icon" size="18" />
              {{ item.label }}
            </span>
            <span
              v-if="item.badge"
              class="rounded-full px-1.5 py-0.5 text-[10px] font-medium"
              :class="activeNav === item.label ? 'bg-white/20 text-white' : 'bg-fuchsia-50 text-fuchsia-600'"
            >
              {{ item.badge }}
            </span>
          </button>
        </nav>
      </div>

      <!-- profile card -->
      <div class="rounded-2xl border border-slate-100 bg-slate-50 p-4">
        <div class="flex items-center gap-3">
          <span class="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-fuchsia-500 to-violet-600 text-xs font-semibold text-white">
            {{ user.initials }}
          </span>
          <div class="min-w-0">
            <p class="truncate text-sm font-medium text-slate-900">{{ user.name }}</p>
            <p class="truncate text-xs text-slate-400">{{ user.role }}</p>
          </div>
        </div>
        <button class="mt-4 flex w-full items-center justify-center gap-1.5 rounded-lg bg-rose-50 py-2 text-xs font-medium text-rose-500 transition hover:bg-rose-100">
          <v-icon icon="mdi-logout" size="15" />
          Logout
        </button>
      </div>
    </aside>

    <!-- ============ MAIN ============ -->
    <div class="flex-1">

      <!-- topbar -->
      <header class="flex flex-wrap items-center justify-between gap-4 border-b border-slate-100 bg-white px-6 py-4 lg:px-10">
        <div class="flex w-full max-w-sm items-center gap-2 rounded-xl bg-slate-50 px-3 py-2.5 sm:w-auto sm:flex-1">
          <i class="fa-solid fa-magnifying-glass text-xs text-slate-400"></i>
          <input
            type="text"
            placeholder="Search markets, assets..."
            class="w-full bg-transparent text-sm text-slate-700 placeholder-slate-400 outline-none"
          />
        </div>

        <div class="flex items-center gap-6">
          <button class="hidden items-center gap-1 text-sm text-slate-500 transition hover:text-slate-900 sm:flex">
            Trades
            <v-icon icon="mdi-chevron-down" size="16" />
          </button>
          <button class="hidden text-sm text-slate-500 transition hover:text-slate-900 sm:flex">Support</button>
          <button class="hidden items-center gap-1 text-sm text-slate-500 transition hover:text-slate-900 sm:flex">
            <v-icon icon="mdi-earth" size="16" />
            Language
          </button>
          <button class="flex items-center gap-1.5 rounded-full bg-gradient-to-r from-fuchsia-500 to-rose-400 px-4 py-2 text-sm font-medium text-white shadow-md shadow-fuchsia-500/20 transition hover:brightness-110">
            New Trade
          </button>
          <button class="relative text-slate-400 transition hover:text-slate-700">
            <v-icon icon="mdi-bell-outline" size="20" />
            <span class="absolute -right-0.5 -top-0.5 h-2 w-2 rounded-full bg-fuchsia-500"></span>
          </button>
        </div>
      </header>

      <!-- content grid -->
      <main class="px-6 py-8 lg:px-10">
        <!-- wallet view card -->
        <div class="card-wallet rounded-3xl border border-slate-100 bg-white p-5">
          <div class="flex items-center justify-between">
            <span class="flex items-center gap-2 text-sm font-medium text-slate-700">
              <span class="flex h-7 w-7 items-center justify-center rounded-full bg-fuchsia-50 text-fuchsia-500">
                <v-icon icon="mdi-wallet-outline" size="15" />
              </span>
              Wallet balance
              <v-icon icon="mdi-chevron-right" size="15" class="text-slate-300" />
            </span>
            <span class="rounded-full bg-emerald-50 px-2 py-0.5 text-[11px] font-medium text-emerald-600">Live</span>
          </div>

          <div class="mt-4 flex items-end justify-between">
            <div class="flex items-baseline gap-2">
              <span class="text-2xl font-semibold text-slate-900">{{ wallet.total }}</span>
            </div>
            
          </div>

          
        </div>

       

      </main>
    </div>
  </div>
</template>

<style scoped>
.dashboard-grid {
  display: grid;
  gap: 1.25rem;
  grid-template-columns: 1fr;
  grid-template-areas:
    'promo'
    'shortcuts'
    'wallet'
    'offer'
    'stats'
    'news';
}

.card-promo { grid-area: promo; }
.card-shortcuts { grid-area: shortcuts; }
.card-offer { grid-area: offer; }
.card-wallet { grid-area: wallet; }
.card-stats { grid-area: stats; }
.card-news { grid-area: news; }

@media (min-width: 1024px) {
  .dashboard-grid {
    grid-template-columns: 1.3fr 1fr 0.9fr;
    grid-template-rows: auto auto auto;
    grid-template-areas:
      'promo shortcuts offer'
      'promo wallet offer'
      'stats stats news';
  }
}
</style>