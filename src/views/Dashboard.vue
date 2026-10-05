<script setup>
import MainLayout from '@/layouts/full/MainLayout.vue'
import { ref, computed } from 'vue'

const activeNav = ref('Home')

const sidebarNav = [
  { label: 'Home', icon: 'mdi-view-dashboard-outline' },
  { label: 'Wallet', icon: 'mdi-wallet-outline', badge: 7 },
  { label: 'Orders', icon: 'mdi-swap-horizontal-bold', badge: 10 },
  { label: 'Activity', icon: 'mdi-pulse' },
  { label: 'Watchlist', icon: 'mdi-star-outline' },
  { label: 'Markets', icon: 'mdi-chart-box-outline' },
  { label: 'Settings', icon: 'mdi-cog-outline' }
]

const user = ref({
  name: 'Alex Carter',
  role: 'Premium Trader',
  initials: 'AC'
})

const shortcuts = [
  { label: 'Markets', icon: 'mdi-chart-line' },
  { label: 'Invest', icon: 'mdi-piggy-bank-outline' },
  { label: 'Convert', icon: 'mdi-swap-horizontal' },
  { label: 'Alerts', icon: 'mdi-bell-outline' },
  { label: 'News', icon: 'mdi-newspaper-variant-outline' }
]

const wallet = ref({
  total: '$15.00',
  changePercent: -1.7,
  deposits: '4,240',
  withdrawals: '1,180',
  btc: '0.42',
  sparkline: '0,28 12,20 24,24 36,12 48,16 60,6 72,10 84,2'
})

const referral = ref({
  title: 'Invite a friend, earn rewards',
  subtitle: 'Share your referral link and both of you get $10 in trading credit.',
  avatarSeeds: ['J', 'M', 'R']
})

const statFilter = ref('Monthly')
const statSeries = ref({
  months: ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'],
  buyPoint: '$21,720',
  sellPoint: '$19,730',
  buyPath: '0,70 40,50 80,60 120,20 160,35 200,10 240,30 280,15',
  sellPath: '0,40 40,55 80,35 120,60 160,45 200,65 240,40 280,55'
})

const newsletter = ref({
  email: ''
})

const activeMarket = ref('All')

const marketCategories = ['All', 'Forex', 'Shares', 'Crypto']

const tradeSignals = ref([
  {
    id: 1,
    market: 'Forex',
    pair: 'EUR/USD',
    asset: 'Euro / US Dollar',
    direction: 'BUY',
    entry: 1.0845,
    target: 1.091,
    stopLoss: 1.08,
    timeframe: '4H',
    strength: 82,
    status: 'Active',
    icon: 'mdi-currency-eur'
  },
  {
    id: 2,
    market: 'Forex',
    pair: 'GBP/USD',
    asset: 'British Pound / US Dollar',
    direction: 'SELL',
    entry: 1.271,
    target: 1.263,
    stopLoss: 1.276,
    timeframe: '1H',
    strength: 76,
    status: 'Active',
    icon: 'mdi-currency-gbp'
  },
  {
    id: 3,
    market: 'Forex',
    pair: 'USD/JPY',
    asset: 'US Dollar / Japanese Yen',
    direction: 'BUY',
    entry: 149.5,
    target: 150.3,
    stopLoss: 148.9,
    timeframe: '4H',
    strength: 79,
    status: 'Active',
    icon: 'mdi-currency-usd'
  },
  {
    id: 4,
    market: 'Shares',
    pair: 'AAPL',
    asset: 'Apple Inc.',
    direction: 'BUY',
    entry: 225.0,
    target: 232.0,
    stopLoss: 221.0,
    timeframe: '1D',
    strength: 85,
    status: 'Active',
    icon: 'mdi-apple'
  },
  {
    id: 5,
    market: 'Shares',
    pair: 'NVDA',
    asset: 'NVIDIA Corporation',
    direction: 'BUY',
    entry: 140.0,
    target: 147.0,
    stopLoss: 136.0,
    timeframe: '4H',
    strength: 80,
    status: 'Active',
    icon: 'mdi-chart-line'
  },
  {
    id: 6,
    market: 'Shares',
    pair: 'TSLA',
    asset: 'Tesla Inc.',
    direction: 'SELL',
    entry: 330.0,
    target: 315.0,
    stopLoss: 340.0,
    timeframe: '1D',
    strength: 72,
    status: 'Active',
    icon: 'mdi-car-electric'
  },
  {
    id: 7,
    market: 'Crypto',
    pair: 'BTC/USDT',
    asset: 'Bitcoin',
    direction: 'BUY',
    entry: 67450,
    target: 68900,
    stopLoss: 66600,
    timeframe: '4H',
    strength: 87,
    status: 'Active',
    icon: 'mdi-bitcoin'
  },
  {
    id: 8,
    market: 'Crypto',
    pair: 'ETH/USDT',
    asset: 'Ethereum',
    direction: 'SELL',
    entry: 3520,
    target: 3380,
    stopLoss: 3600,
    timeframe: '1H',
    strength: 74,
    status: 'Active',
    icon: 'mdi-ethereum'
  },
  {
    id: 9,
    market: 'Crypto',
    pair: 'SOL/USDT',
    asset: 'Solana',
    direction: 'BUY',
    entry: 148.5,
    target: 156.0,
    stopLoss: 144.0,
    timeframe: '4H',
    strength: 81,
    status: 'Active',
    icon: 'mdi-chart-line'
  }
])

const filteredSignals = computed(() => {
  if (activeMarket.value === 'All') {
    return tradeSignals.value
  }

  return tradeSignals.value.filter((signal) => signal.market === activeMarket.value)
})

const demoMarkets = ref([
  { pair: 'BTC/USDT', name: 'Bitcoin', price: 67450, change: 2.84, icon: 'mdi-bitcoin' },
  { pair: 'ETH/USDT', name: 'Ethereum', price: 3520, change: -1.25, icon: 'mdi-ethereum' },
  { pair: 'SOL/USDT', name: 'Solana', price: 148.5, change: 4.62, icon: 'mdi-chart-line' },
  { pair: 'XRP/USDT', name: 'XRP', price: 0.625, change: -0.83, icon: 'mdi-alpha-x-circle-outline' }
])

const demoOrders = ref([])

const tradeDialog = ref(false)
const selectedTrade = ref(null)
const tradeSide = ref('BUY')
const tradeAmount = ref(100)
const tradeMessage = ref('')

const openTrade = (signal, side = signal.direction) => {
  selectedTrade.value = signal
  tradeSide.value = side
  tradeAmount.value = 100
  tradeMessage.value = ''
  tradeDialog.value = true
}

const submitDemoTrade = () => {
  if (!selectedTrade.value || tradeAmount.value <= 0) {
    tradeMessage.value = 'Enter a valid trade amount.'
    return
  }

  const signal = selectedTrade.value

  demoOrders.value.unshift({
    id: Date.now(),
    pair: signal.pair,
    side: tradeSide.value,
    amount: Number(tradeAmount.value),
    entry: signal.entry,
    status: 'Demo order placed',
    time: new Date().toLocaleTimeString()
  })

  tradeMessage.value = `Demo ${tradeSide.value} order recorded for ${signal.pair}. No real trade was executed.`
}

import FundWalletDialog from '@/components/FundwalletDialog.vue' 

const fundDialog = ref(false)

// Replace these placeholders with your real details
const paymentDetails = {
  paypal: { email: 'pay@yourcompany.com' },
  venmo: { handle: '@yourcompany' },
  btc: { network: 'Bitcoin', address: 'bc1q...' },
  bank: { bankName: '...', accountName: '...', accountNumber: '...' },
  cashapp: { cashtag: '$yourcompany' }
}

const handleFundSubmit = (payload) => {
  // payload: { amount, method, methodLabel, reference }
  console.log('Fund request:', payload)
  fundDialog.value = false
  // TODO: save to Supabase / call your API so you can verify and credit the wallet
}
</script>

<template>
  <main-layout>
    <!-- content grid -->
    <div class="px-6 py-8 lg:px-10">
      <!-- wallet view card -->
      <div class="card-wallet rounded-3xl border border-slate-100 bg-white p-5">
        <div class="flex items-center justify-between">
          <span class="flex items-center gap-2 text-sm font-medium text-slate-700">
            <span
              class="flex h-7 w-7 items-center justify-center rounded-full bg-fuchsia-50 text-fuchsia-500"
            >
              <v-icon icon="mdi-wallet-outline" size="15" />
            </span>
            Wallet balance
            <v-icon icon="mdi-chevron-right" size="15" class="text-slate-300" />
          </span>
          <div class="flex items-center gap-2">
            
            <button
              type="button"
              @click="fundDialog = true"
              class="flex items-center gap-1.5 rounded-full bg-gradient-to-r from-[#7928df] to-[#e13e9c] px-4 py-1.5 text-xs font-semibold text-white transition hover:shadow-lg"
            >
              <v-icon icon="mdi-plus" size="14" />
              Fund wallet
            </button>
          </div>
        </div>

        <div class="mt-4 flex items-end justify-between">
          <div class="flex items-baseline gap-2">
            <span class="text-2xl font-semibold text-slate-900">{{ wallet.total }}</span>
          </div>
        </div>
      </div>

      <!-- TRADE SIGNALS -->
      <section class="mt-8">
        <div class="mb-5 flex flex-wrap items-center justify-between gap-3">
          <div>
            <div class="flex items-center gap-2">
              <h2 class="text-xl font-semibold text-slate-900">Trade Signals</h2>
            </div>
          </div>

          <!-- <button
              class="flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm text-slate-600 hover:bg-slate-50"
              @click="tradeSignals = [...tradeSignals]"
            >
              <v-icon icon="mdi-refresh" size="16" />
              Refresh
            </button> -->
        </div>

        <div class="mb-5 flex flex-wrap gap-2">
          <button
            v-for="market in marketCategories"
            :key="market"
            @click="activeMarket = market"
            class="rounded-full px-4 py-2 text-sm font-medium transition"
            :class="
              activeMarket === market
                ? 'bg-slate-900 text-white'
                : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
            "
          >
            {{ market }}
          </button>
        </div>

        <div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
          <article
            v-for="signal in filteredSignals"
            :key="signal.id"
            class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm"
          >
            <!-- Keep your existing signal card content here. -->

            <div class="mb-3 flex items-center justify-between">
              <span class="rounded-md bg-violet-50 px-2 py-1 text-xs text-violet-600">
                {{ signal.market }}
              </span>
              <span class="text-xs text-slate-400">
                {{ signal.timeframe }}
              </span>
            </div>

            <h3 class="font-semibold text-slate-900">
              {{ signal.pair }}
            </h3>
            <p class="text-xs text-slate-400">
              {{ signal.asset }}
            </p>

            <div class="mt-4 grid grid-cols-2 gap-3 text-sm">
              <div>
                <p class="text-xs text-slate-400">Entry</p>
                <p class="mt-1 font-medium">
                  {{ signal.entry.toLocaleString() }}
                </p>
              </div>
              <div>
                <p class="text-xs text-slate-400">Take profit</p>
                <p class="mt-1 font-medium text-emerald-600">
                  {{ signal.target.toLocaleString() }}
                </p>
              </div>
              <div>
                <p class="text-xs text-slate-400">Stop loss</p>
                <p class="mt-1 font-medium text-rose-500">
                  {{ signal.stopLoss.toLocaleString() }}
                </p>
              </div>
              <div>
                <p class="text-xs text-slate-400">Signal strength</p>
                <p class="mt-1 font-medium">{{ signal.strength }}%</p>
              </div>
            </div>

            <div class="mt-5 grid grid-cols-2 gap-3">
              <button
                @click="openTrade(signal, 'BUY')"
                class="rounded-xl bg-emerald-500 py-2.5 text-sm font-semibold text-white"
              >
                Buy
              </button>
              <button
                @click="openTrade(signal, 'SELL')"
                class="rounded-xl bg-rose-500 py-2.5 text-sm font-semibold text-white"
              >
                Sell
              </button>
            </div>
          </article>
        </div>

        <div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
          <article
            v-for="signal in filteredSignals"
            :key="signal.id"
            class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm transition hover:shadow-md"
          >
            <div class="flex items-start justify-between">
              <div class="flex items-center gap-3">
                <span
                  class="flex h-11 w-11 items-center justify-center rounded-xl"
                  :class="
                    signal.direction === 'BUY'
                      ? 'bg-emerald-50 text-emerald-600'
                      : 'bg-rose-50 text-rose-500'
                  "
                >
                  <v-icon :icon="signal.icon" size="24" />
                </span>

                <div>
                  <h3 class="font-semibold text-slate-900">
                    {{ signal.pair }}
                  </h3>
                  <p class="text-xs text-slate-400">{{ signal.asset }} · {{ signal.timeframe }}</p>
                </div>
              </div>

              <span
                class="rounded-full px-2.5 py-1 text-xs font-semibold"
                :class="
                  signal.direction === 'BUY'
                    ? 'bg-emerald-50 text-emerald-600'
                    : 'bg-rose-50 text-rose-500'
                "
              >
                {{ signal.direction }}
              </span>
            </div>

            <div class="mt-5 grid grid-cols-2 gap-4">
              <div>
                <p class="text-xs text-slate-400">Entry price</p>
                <p class="mt-1 font-semibold text-slate-800">
                  {{
                    signal.entry.toLocaleString('en-US', {
                      minimumFractionDigits: 2,
                      maximumFractionDigits: 4
                    })
                  }}
                </p>
              </div>

              <div>
                <p class="text-xs text-slate-400">Take profit</p>
                <p class="mt-1 font-semibold text-emerald-600">
                  {{
                    signal.target.toLocaleString('en-US', {
                      minimumFractionDigits: 2,
                      maximumFractionDigits: 4
                    })
                  }}
                </p>
              </div>

              <div>
                <p class="text-xs text-slate-400">Stop loss</p>
                <p class="mt-1 font-semibold text-rose-500">
                  {{
                    signal.stopLoss.toLocaleString('en-US', {
                      minimumFractionDigits: 2,
                      maximumFractionDigits: 4
                    })
                  }}
                </p>
              </div>

              <div>
                <p class="text-xs text-slate-400">Signal strength</p>
                <p class="mt-1 font-semibold text-slate-800">{{ signal.strength }}%</p>
                <div class="mt-2 h-1.5 overflow-hidden rounded-full bg-slate-100">
                  <div
                    class="h-full rounded-full"
                    :class="signal.direction === 'BUY' ? 'bg-emerald-500' : 'bg-rose-400'"
                    :style="{ width: `${signal.strength}%` }"
                  ></div>
                </div>
              </div>
            </div>

            <div class="mt-5 grid grid-cols-2 gap-3">
              <button
                @click="openTrade(signal, 'BUY')"
                class="rounded-xl bg-emerald-500 px-3 py-2.5 text-sm font-semibold text-white transition hover:bg-emerald-600"
              >
                Buy
              </button>

              <button
                @click="openTrade(signal, 'SELL')"
                class="rounded-xl bg-rose-500 px-3 py-2.5 text-sm font-semibold text-white transition hover:bg-rose-600"
              >
                Sell
              </button>
            </div>
          </article>
        </div>
      </section>

      <!-- MARKET WATCHLIST -->
      <section class="mt-10">
        <div class="mb-5">
          <h2 class="text-xl font-semibold text-slate-900">Market Watchlist</h2>
          <p class="mt-1 text-sm text-slate-500">Explore available trading pairs.</p>
        </div>

        <div class="overflow-hidden rounded-2xl border border-slate-100 bg-white">
          <div class="overflow-x-auto">
            <table class="w-full min-w-[600px] text-left text-sm">
              <thead class="bg-slate-50 text-xs text-slate-400">
                <tr>
                  <th class="px-5 py-4 font-medium">Asset</th>
                  <th class="px-5 py-4 font-medium">Price</th>
                  <th class="px-5 py-4 font-medium">24h change</th>
                  <th class="px-5 py-4 text-right font-medium">Action</th>
                </tr>
              </thead>

              <tbody>
                <tr
                  v-for="market in demoMarkets"
                  :key="market.pair"
                  class="border-t border-slate-100 hover:bg-slate-50"
                >
                  <td class="px-5 py-4">
                    <div class="flex items-center gap-3">
                      <v-icon :icon="market.icon" size="24" class="text-violet-500" />
                      <div>
                        <p class="font-medium text-slate-800">
                          {{ market.pair }}
                        </p>
                        <p class="text-xs text-slate-400">
                          {{ market.name }}
                        </p>
                      </div>
                    </div>
                  </td>

                  <td class="px-5 py-4 font-medium text-slate-800">
                    ${{
                      market.price.toLocaleString('en-US', {
                        maximumFractionDigits: 4
                      })
                    }}
                  </td>

                  <td class="px-5 py-4">
                    <span :class="market.change >= 0 ? 'text-emerald-600' : 'text-rose-500'">
                      {{ market.change > 0 ? '+' : '' }}{{ market.change }}%
                    </span>
                  </td>

                  <td class="px-5 py-4 text-right">
                    <button
                      @click="
                        openTrade(
                          {
                            pair: market.pair,
                            entry: market.price,
                            target: market.price,
                            stopLoss: market.price,
                            direction: 'BUY'
                          },
                          'BUY'
                        )
                      "
                      class="rounded-full bg-slate-900 px-4 py-2 text-xs font-medium text-white transition hover:bg-slate-700"
                    >
                      Trade
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- RECENT DEMO ORDERS -->
      <section class="mt-10">
        <div class="mb-5 flex items-center justify-between">
          <div>
            <h2 class="text-xl font-semibold text-slate-900">Recent Trades</h2>
            <p class="mt-1 text-sm text-slate-500">Your simulated order activity.</p>
          </div>
          <span class="rounded-full bg-slate-100 px-3 py-1 text-xs text-slate-500">
            {{ demoOrders.length }} orders
          </span>
        </div>

        <div class="overflow-hidden rounded-2xl border border-slate-100 bg-white">
          <div v-if="demoOrders.length === 0" class="px-6 py-10 text-center">
            <v-icon icon="mdi-swap-horizontal" size="32" class="text-slate-300" />
            <p class="mt-3 font-medium text-slate-700">No trades yet</p>
            <p class="mt-1 text-sm text-slate-400">
              Choose a signal and place a order to get started.
            </p>
          </div>

          <div v-else class="overflow-x-auto">
            <table class="w-full min-w-[560px] text-left text-sm">
              <thead class="bg-slate-50 text-xs text-slate-400">
                <tr>
                  <th class="px-5 py-4 font-medium">Pair</th>
                  <th class="px-5 py-4 font-medium">Side</th>
                  <th class="px-5 py-4 font-medium">Amount</th>
                  <th class="px-5 py-4 font-medium">Entry</th>
                  <th class="px-5 py-4 font-medium">Status</th>
                </tr>
              </thead>

              <tbody>
                <tr v-for="order in demoOrders" :key="order.id" class="border-t border-slate-100">
                  <td class="px-5 py-4 font-medium text-slate-800">
                    {{ order.pair }}
                  </td>
                  <td class="px-5 py-4">
                    <span :class="order.side === 'BUY' ? 'text-emerald-600' : 'text-rose-500'">
                      {{ order.side }}
                    </span>
                  </td>
                  <td class="px-5 py-4 text-slate-700">${{ order.amount.toLocaleString() }}</td>
                  <td class="px-5 py-4 text-slate-700">
                    ${{
                      order.entry.toLocaleString('en-US', {
                        maximumFractionDigits: 4
                      })
                    }}
                  </td>
                  <td class="px-5 py-4">
                    <span class="rounded-full bg-amber-50 px-2.5 py-1 text-xs text-amber-700">
                      {{ order.status }}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- DEMO TRADE DIALOG -->
      <v-dialog v-model="tradeDialog" max-width="440">
        <div class="rounded-3xl bg-white p-6">
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-semibold text-slate-900">Place Trade</h2>

            <button @click="tradeDialog = false" class="text-slate-400 hover:text-slate-700">
              <v-icon icon="mdi-close" />
            </button>
          </div>

          <p class="mt-2 text-sm text-slate-500">
            {{ selectedTrade?.pair }}
            · Illustrative price: ${{
              selectedTrade?.entry?.toLocaleString('en-US', {
                maximumFractionDigits: 4
              })
            }}
          </p>

          <div class="mt-5 grid grid-cols-2 gap-3">
            <button
              @click="tradeSide = 'BUY'"
              :class="
                tradeSide === 'BUY' ? 'bg-emerald-500 text-white' : 'bg-slate-100 text-slate-600'
              "
              class="rounded-xl py-3 text-sm font-semibold"
            >
              Buy
            </button>

            <button
              @click="tradeSide = 'SELL'"
              :class="
                tradeSide === 'SELL' ? 'bg-rose-500 text-white' : 'bg-slate-100 text-slate-600'
              "
              class="rounded-xl py-3 text-sm font-semibold"
            >
              Sell
            </button>
          </div>

          <label class="mt-5 block text-sm font-medium text-slate-700"> Trade amount (USD) </label>

          <div class="mt-2 flex items-center rounded-xl border border-slate-200 px-4">
            <span class="text-slate-400">$</span>
            <input
              v-model.number="tradeAmount"
              type="number"
              min="1"
              step="1"
              class="w-full bg-transparent px-3 py-3 outline-none"
              placeholder="Enter amount"
            />
          </div>

          <div class="mt-4 rounded-xl bg-slate-50 p-4">
            <div class="flex justify-between text-sm">
              <span class="text-slate-500">Estimated quantity</span>
              <span class="font-medium text-slate-800">
                {{
                  selectedTrade && selectedTrade.entry > 0
                    ? (Math.max(0, Number(tradeAmount) || 0) / selectedTrade.entry).toFixed(6)
                    : '0.000000'
                }}
              </span>
            </div>
          </div>

          <p
            v-if="tradeMessage"
            class="mt-4 rounded-xl bg-slate-50 p-3 text-sm text-slate-600"
            role="status"
          >
            {{ tradeMessage }}
          </p>

          <button
            @click="submitDemoTrade"
            class="mt-5 w-full rounded-xl py-3 font-semibold text-white transition"
            :class="
              tradeSide === 'BUY'
                ? 'bg-emerald-500 hover:bg-emerald-600'
                : 'bg-rose-500 hover:bg-rose-600'
            "
          >
            Confirm {{ tradeSide }}
          </button>

          <button
            @click="tradeDialog = false"
            class="mt-3 w-full py-2 text-sm text-slate-500 hover:text-slate-800"
          >
            Cancel
          </button>
        </div>
      </v-dialog>
      <FundWalletDialog
        v-model="fundDialog"
        :payment-details="paymentDetails"
        @submit="handleFundSubmit"
      />
    </div>
  </main-layout>
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

.card-promo {
  grid-area: promo;
}
.card-shortcuts {
  grid-area: shortcuts;
}
.card-offer {
  grid-area: offer;
}
.card-wallet {
  grid-area: wallet;
}
.card-stats {
  grid-area: stats;
}
.card-news {
  grid-area: news;
}

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
