<script setup>
import { ref } from 'vue'

const navLinks = [
  { label: 'Markets', hasChevron: true },
  { label: 'Instruments', hasChevron: true },
  { label: 'Platforms', hasChevron: true },
  { label: 'Tools', hasChevron: false },
  { label: 'Learning Center', hasChevron: false },
]

const exchangeQuote = ref({
  sell: { symbol: 'INJ', name: 'Injective', icon: 'mdi-hexagon-slice-6', price: '276.55', change: '-$88.31' },
  buy: { symbol: 'ZRX', name: '0x Protocol', icon: 'mdi-alpha-z-circle-outline', price: '28,582.67', change: '-$88.27  0.04%' },
})

const portfolioGrowth = ref({
  since: 'Since Yesterday',
  label: 'Your Assets Have Grown by',
  amount: '$755.47',
  sparkline: '0,28 12,20 24,24 36,12 48,16 60,6 72,10 84,2',
})

const assetTickers = [
  { symbol: 'BTC', icon: 'mdi-bitcoin' },
  { symbol: 'ETH', icon: 'mdi-ethereum' },
  { symbol: 'USDT', icon: 'mdi-currency-usd' },
  { symbol: 'BNB', icon: 'mdi-hexagon-outline' },
  { symbol: 'FLOW', icon: 'mdi-water-outline' },
]

const avatarSeeds = ['A', 'M', 'J', 'S']

const marketRows = [
  { name: 'Chain', symbol: 'LNK', icon: 'mdi-link-variant', price: '$18.31', change: 9.97, volume: '587.1M LNK', trend: 'up' },
  { name: 'Mantle', symbol: 'MNT', icon: 'mdi-triangle-outline', price: '$134.59', change: 3.02, volume: '3.7B MNT', trend: 'up' },
  { name: 'XRP', symbol: 'XRP', icon: 'mdi-alpha-x-circle-outline', price: '$0.5023', change: -5.00, volume: '1.4B XRP', trend: 'down' },
  { name: 'Stellar', symbol: 'XLM', icon: 'mdi-star-four-points-outline', price: '$0.1076', change: -3.38, volume: '28.3B XLM', trend: 'down' },
  { name: 'Cardano', symbol: 'ADA', icon: 'mdi-cards-outline', price: '$1.25', change: -6.05, volume: '31.9B ADA', trend: 'down' },
]

const marketFilters = ['Popular Today', 'All categories']
const activeFilter = ref('Popular Today')
const searchQuery = ref('')
</script>

<template>
  <div class="min-h-screen bg-[#f5f6fa] text-slate-800 antialiased selection:bg-fuchsia-100">

    <!-- ============ NAV ============ -->
    <header class="relative z-20 border-b border-slate-100 bg-white/70 backdrop-blur">
      <nav class="mx-auto flex max-w-7xl items-center justify-between px-6 py-5 lg:px-10">
        <div class="hidden items-center gap-6 lg:flex">
          <button
            v-for="link in navLinks"
            :key="link.label"
            class="flex items-center gap-1 text-sm text-slate-500 transition hover:text-slate-900"
          >
            {{ link.label }}
            <v-icon v-if="link.hasChevron" icon="mdi-chevron-down" size="16" />
          </button>
        </div>

        <a href="#" class="flex items-center gap-2 lg:absolute lg:left-1/2 lg:-translate-x-1/2">
          <span class="flex h-9 w-9 items-center justify-center rounded-lg bg-gradient-to-br from-fuchsia-500 to-violet-600">
            <i class="fa-solid fa-bolt text-sm text-white"></i>
          </span>
          <span class="text-lg font-semibold tracking-tight text-slate-900">BMFX</span>
        </a>

        <div class="flex items-center gap-3">
          <button class="hidden text-sm text-slate-500 transition hover:text-slate-900 sm:flex items-center gap-1">
            About
          </button>
          <button class="hidden items-center gap-1 text-sm text-slate-500 transition hover:text-slate-900 sm:flex">
            More
            <v-icon icon="mdi-dots-horizontal" size="16" />
          </button>
          <button class="rounded-full border border-slate-200 px-4 py-2 text-sm text-slate-700 transition hover:bg-slate-50">
            Sign In
          </button>
          <button class="flex items-center gap-1.5 rounded-full bg-gradient-to-r from-fuchsia-500 to-rose-400 px-4 py-2 text-sm font-medium text-white shadow-md shadow-fuchsia-500/20 transition hover:brightness-110">
            Join BMFX
            <v-icon icon="mdi-arrow-right" size="16" />
          </button>
        </div>
      </nav>
    </header>

    <!-- ============ HERO ============ -->
    <section class="relative overflow-hidden">
      <!-- ambient soft backdrop -->
      <div class="pointer-events-none absolute inset-0 -z-10">
        <div class="absolute right-0 top-[-10%] h-[600px] w-[600px] rounded-full bg-fuchsia-100/60 blur-[140px]"></div>
        <div class="absolute right-1/4 top-1/3 h-[400px] w-[400px] rounded-full bg-violet-100/60 blur-[120px]"></div>
      </div>

      <div class="mx-auto max-w-4xl px-6 pb-20 pt-14 text-center lg:pt-20">
        <span class="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-1.5 text-xs text-slate-500 shadow-sm">
          <v-icon icon="mdi-chevron-up" size="14" class="text-fuchsia-500" />
          Built for Various Crypto and Fiat Solutions
        </span>

        <h1 class="mt-8 text-5xl font-bold leading-[1.05] tracking-tight text-slate-900 sm:text-6xl lg:text-7xl">
          Boost Your Finance
          <br class="hidden sm:block" />
          Potential with BMFX
        </h1>

        <p class="mx-auto mt-6 max-w-xl text-balance text-slate-500">
          Focus on growth while we take care of payments: coverage, liquidity, chargebacks, support, anti-fraud.
        </p>

        <div class="mt-9 flex flex-wrap items-center justify-center gap-3">
          <button class="flex items-center gap-2 rounded-full bg-gradient-to-r from-fuchsia-500 to-rose-400 px-6 py-3 text-sm font-medium text-white shadow-md shadow-fuchsia-500/25 transition hover:brightness-110">
            Open Dashboard
            <v-icon icon="mdi-arrow-right" size="16" />
          </button>
          <button class="rounded-full border border-slate-200 bg-white px-6 py-3 text-sm font-medium text-slate-700 transition hover:bg-slate-50">
            Explore More
          </button>
        </div>
      </div>

      <!-- ============ FLOATING STAT CARDS ============ -->
      <div class="mx-auto grid max-w-7xl grid-cols-1 gap-4 px-6 pb-8 sm:grid-cols-2 lg:grid-cols-4 lg:px-10">

        <!-- customers / rating card -->
        <div class="rounded-3xl border border-slate-100 bg-white p-5 shadow-sm">
          <p class="text-xs text-slate-400">Trusted over by 250k+ customers</p>
          <div class="mt-4 flex -space-x-2">
            <span
              v-for="seed in avatarSeeds"
              :key="seed"
              class="flex h-8 w-8 items-center justify-center rounded-full border-2 border-white bg-gradient-to-br from-fuchsia-400 to-violet-500 text-xs font-medium text-white"
            >
              {{ seed }}
            </span>
          </div>
          <div class="mt-5 flex items-center gap-1.5">
            <i class="fa-solid fa-star text-amber-400 text-sm"></i>
            <span class="text-2xl font-semibold text-slate-900">4.7</span>
          </div>
          <div class="mt-4 flex items-center gap-2">
            <span class="flex items-center gap-1.5 rounded-lg border border-slate-200 px-2.5 py-1.5 text-[11px] text-slate-500">
              <i class="fa-brands fa-apple"></i> App Store
            </span>
            <span class="flex items-center gap-1.5 rounded-lg border border-slate-200 px-2.5 py-1.5 text-[11px] text-slate-500">
              <i class="fa-brands fa-google-play"></i> Google Play
            </span>
          </div>
        </div>

        <!-- exchange rates card -->
        <div class="rounded-3xl border border-slate-100 bg-white p-5 shadow-sm">
          <div class="flex items-center justify-between">
            <p class="text-xs text-slate-400">Exchange at Favorable Rates</p>
            <v-icon icon="mdi-arrow-expand" size="15" class="text-slate-300" />
          </div>

          <div class="mt-4 space-y-2">
            <div class="rounded-2xl bg-slate-50 p-3">
              <p class="text-[11px] text-slate-400">You sell</p>
              <div class="mt-1.5 flex items-center justify-between">
                <span class="flex items-center gap-1.5 text-sm font-medium text-slate-800">
                  <v-icon :icon="exchangeQuote.sell.icon" size="18" class="text-fuchsia-500" />
                  {{ exchangeQuote.sell.symbol }}
                  <v-icon icon="mdi-chevron-down" size="14" class="text-slate-300" />
                </span>
                <span class="text-sm font-medium text-slate-800">{{ exchangeQuote.sell.price }}</span>
              </div>
              <div class="mt-0.5 flex items-center justify-between text-[11px] text-slate-400">
                <span>{{ exchangeQuote.sell.name }}</span>
                <span class="text-rose-500">{{ exchangeQuote.sell.change }}</span>
              </div>
            </div>

            <div class="flex justify-center">
              <span class="flex h-7 w-7 items-center justify-center rounded-full border border-slate-200 bg-white shadow-sm">
                <v-icon icon="mdi-swap-vertical" size="16" class="text-slate-500" />
              </span>
            </div>

            <div class="-mt-2 rounded-2xl bg-slate-50 p-3">
              <p class="text-[11px] text-slate-400">You buy</p>
              <div class="mt-1.5 flex items-center justify-between">
                <span class="flex items-center gap-1.5 text-sm font-medium text-slate-800">
                  <v-icon :icon="exchangeQuote.buy.icon" size="18" class="text-violet-500" />
                  {{ exchangeQuote.buy.symbol }}
                  <v-icon icon="mdi-chevron-down" size="14" class="text-slate-300" />
                </span>
                <span class="text-sm font-medium text-slate-800">{{ exchangeQuote.buy.price }}</span>
              </div>
              <div class="mt-0.5 flex items-center justify-between text-[11px] text-slate-400">
                <span>{{ exchangeQuote.buy.name }}</span>
                <span class="text-rose-500">{{ exchangeQuote.buy.change }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- insights card -->
        <div class="flex flex-col justify-between rounded-3xl border border-slate-100 bg-white p-5 shadow-sm">
          <div class="flex items-center justify-between">
            <span class="rounded-full border border-slate-200 px-3 py-1 text-[11px] text-slate-500">
              Wallet
              <v-icon icon="mdi-chevron-down" size="12" />
            </span>
            <v-icon icon="mdi-arrow-expand" size="15" class="text-slate-300" />
          </div>

          <div class="my-4">
            <svg viewBox="0 0 84 32" class="h-12 w-full">
              <polyline :points="portfolioGrowth.sparkline" fill="none" stroke="#a855f7" stroke-width="2" stroke-linecap="round" />
            </svg>
          </div>

          <div>
            <p class="text-[11px] text-slate-400">{{ portfolioGrowth.since }}</p>
            <p class="text-sm text-slate-600">
              {{ portfolioGrowth.label }}
              <span class="font-semibold text-emerald-500">{{ portfolioGrowth.amount }}</span>
            </p>
          </div>
        </div>

        <!-- assets list card -->
        <div class="rounded-3xl border border-slate-100 bg-white p-5 shadow-sm">
          <p class="text-xs text-slate-400">Various Assets Covered</p>
          <ul class="mt-4 space-y-3">
            <li
              v-for="asset in assetTickers"
              :key="asset.symbol"
              class="flex items-center gap-2.5 text-sm text-slate-700"
            >
              <v-icon :icon="asset.icon" size="18" class="text-fuchsia-500" />
              {{ asset.symbol }}
            </li>
          </ul>
        </div>
      </div>
    </section>

    <!-- ============ TRADE ANYWHERE SECTION ============ -->
    <section class="relative border-t border-slate-100 px-6 py-24 lg:px-10">
      <div class="pointer-events-none absolute inset-0 -z-10">
        <div class="absolute left-1/2 top-0 h-[500px] w-[500px] -translate-x-1/2 rounded-full bg-violet-100/50 blur-[160px]"></div>
      </div>

      <div class="mx-auto max-w-2xl text-center">
        <span class="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-1.5 text-xs text-slate-500 shadow-sm">
          <v-icon icon="mdi-chevron-up" size="14" class="text-fuchsia-500" />
          No Cost and Fees Forever — with Lite Subscription Plan
        </span>

        <h2 class="mt-6 text-4xl font-bold tracking-tight text-slate-900 sm:text-5xl">
          Trade anytime,<br />anywhere
        </h2>

        <p class="mx-auto mt-4 max-w-md text-slate-500">
          Elevate your crypto journey with a safe, convenient, and powerful Web3 trading wallet.
        </p>

        <div class="mt-8 flex items-center gap-2 rounded-full border border-slate-200 bg-white p-1.5 pl-5 shadow-sm">
          <v-icon icon="mdi-magnify" size="18" class="text-slate-300" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search cryptocurrency, asset, etc."
            class="flex-1 bg-transparent py-2 text-sm text-slate-800 placeholder-slate-400 outline-none"
          />
          <button class="flex items-center gap-1.5 rounded-full bg-gradient-to-r from-fuchsia-500 to-rose-400 px-4 py-2 text-sm font-medium text-white">
            Search
            <v-icon icon="mdi-plus" size="16" />
          </button>
        </div>
      </div>

      <!-- market table -->
      <div class="mx-auto mt-14 max-w-5xl overflow-hidden rounded-3xl border border-slate-100 bg-white shadow-sm">
        <div class="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 px-6 py-4">
          <div class="flex items-center gap-2">
            <button
              v-for="filter in marketFilters"
              :key="filter"
              @click="activeFilter = filter"
              class="flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs transition"
              :class="activeFilter === filter ? 'bg-slate-900 text-white' : 'text-slate-500 hover:bg-slate-50'"
            >
              <v-icon :icon="filter === 'Popular Today' ? 'mdi-view-grid-outline' : 'mdi-shape-outline'" size="14" />
              {{ filter }}
            </button>
          </div>
          <button class="flex items-center gap-1.5 rounded-full border border-slate-200 px-3 py-1.5 text-xs text-slate-500">
            Today
            <v-icon icon="mdi-chevron-down" size="14" />
          </button>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full min-w-[640px] text-left text-sm">
            <thead>
              <tr class="text-xs text-slate-400">
                <th class="px-6 py-3 font-normal">Coin</th>
                <th class="px-4 py-3 font-normal">Last price</th>
                <th class="px-4 py-3 font-normal">Dynamic</th>
                <th class="px-4 py-3 font-normal">Volume</th>
                <th class="px-4 py-3 font-normal">Chart</th>
                <th class="px-6 py-3 font-normal text-right">Trade</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="row in marketRows"
                :key="row.symbol"
                class="border-t border-slate-100 transition hover:bg-slate-50"
              >
                <td class="flex items-center gap-2.5 px-6 py-4">
                  <v-icon :icon="row.icon" size="20" class="text-fuchsia-500" />
                  <span class="text-slate-800">{{ row.name }}</span>
                  <span class="text-slate-400">{{ row.symbol }}</span>
                </td>
                <td class="px-4 py-4 text-slate-800">{{ row.price }}</td>
                <td class="px-4 py-4">
                  <span
                    class="rounded-md px-2 py-0.5 text-xs font-medium"
                    :class="row.trend === 'up' ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-500'"
                  >
                    {{ row.trend === 'up' ? '+' : '' }}{{ row.change.toFixed(2) }}%
                  </span>
                </td>
                <td class="px-4 py-4 text-slate-400">{{ row.volume }}</td>
                <td class="px-4 py-4">
                  <svg viewBox="0 0 80 24" class="h-6 w-16">
                    <polyline
                      :points="row.trend === 'up' ? '0,20 15,14 30,16 45,8 60,10 80,2' : '0,4 15,10 30,8 45,16 60,14 80,20'"
                      fill="none"
                      :stroke="row.trend === 'up' ? '#10b981' : '#fb7185'"
                      stroke-width="1.5"
                    />
                  </svg>
                </td>
                <td class="px-6 py-4 text-right">
                  <button class="rounded-full border border-slate-200 px-4 py-1.5 text-xs font-medium text-slate-700 transition hover:bg-slate-50">
                    Trade
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>

  </div>
</template>