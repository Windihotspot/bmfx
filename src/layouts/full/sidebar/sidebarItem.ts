const sidebarItems = [
  {
    section: 'TRADING OVERVIEW',
    roles: ['authenticated', 'authenticated'],
    items: [
      {
        title: 'Dashboard',
        path: '/dashboard',
        icon: 'fa-solid fa-chart-pie',
      },
      {
        title: 'Trade Signals',
        path: '/signals',
        icon: 'fa-solid fa-bolt',
        badge: 'NEW',
      },
      {
        title: 'Markets',
        path: '/markets',
        icon: 'fa-solid fa-chart-line',
      },
    ],
  },

  {
    section: 'TRADE',
    roles: ['authenticated', 'authenticated'],
    items: [
      {
        title: 'Forex',
        path: '/markets/forex',
        icon: 'fa-solid fa-money-bill-transfer',
      },
      {
        title: 'Crypto',
        path: '/markets/crypto',
        icon: 'fa-brands fa-bitcoin',
      },
      {
        title: 'Shares',
        path: '/markets/shares',
        icon: 'fa-solid fa-chart-column',
      },
      {
        title: 'Buy / Sell',
        path: '/trade',
        icon: 'fa-solid fa-arrow-right-arrow-left',
      },
      {
        title: 'Open Positions',
        path: '/positions',
        icon: 'fa-solid fa-layer-group',
      },
      {
        title: 'Trade History',
        path: '/trade-history',
        icon: 'fa-solid fa-clock-rotate-left',
      },
    ],
  },

  {
    section: 'PORTFOLIO & FUNDS',
    roles: ['authenticated', 'authenticated'],
    items: [
      {
        title: 'My Portfolio',
        path: '/portfolio',
        icon: 'fa-solid fa-briefcase',
      },
      {
        title: 'Wallet',
        path: '/wallet',
        icon: 'fa-solid fa-wallet',
      },
      {
        title: 'Deposits',
        path: '/deposits',
        icon: 'fa-solid fa-circle-arrow-down',
      },
      {
        title: 'Withdrawals',
        path: '/withdrawals',
        icon: 'fa-solid fa-circle-arrow-up',
      },
      {
        title: 'Transactions',
        path: '/transactions',
        icon: 'fa-solid fa-receipt',
      },
    ],
  },

  {
    section: 'ANALYSIS',
    roles: ['authenticated', 'authenticated'],
    items: [
      {
        title: 'Market Watch',
        path: '/market-watch',
        icon: 'fa-solid fa-eye',
      },
      {
        title: 'Watchlist',
        path: '/watchlist',
        icon: 'fa-solid fa-star',
      },
      {
        title: 'Price Charts',
        path: '/charts',
        icon: 'fa-solid fa-chart-area',
      },
      {
        title: 'Economic Calendar',
        path: '/economic-calendar',
        icon: 'fa-regular fa-calendar-days',
      },
    ],
  },

  {
    section: 'ACCOUNT',
    roles: ['authenticated', 'authenticated'],
    items: [
      {
        title: 'Verification (KYC)',
        path: '/verification',
        icon: 'fa-solid fa-shield-halved',
      },
      {
        title: 'Notifications',
        path: '/notifications',
        icon: 'fa-regular fa-bell',
      },
      {
        title: 'Profile',
        path: '/profile',
        icon: 'fa-regular fa-user',
      },
      {
        title: 'Settings',
        path: '/settings',
        icon: 'fa-solid fa-gear',
      },
      {
        title: 'Help & Support',
        path: '/support',
        icon: 'fa-regular fa-circle-question',
      },
    ],
  },

  {
    section: 'authenticatedISTRATION',
    roles: ['authenticated'],
    items: [
      {
        title: 'Users',
        path: '/authenticated/users',
        icon: 'fa-solid fa-users',
      },
      {
        title: 'Manage Accounts',
        path: '/authenticated/accounts',
        icon: 'fa-solid fa-user-gear',
      },
      {
        title: 'Manage Trade Signals',
        path: '/authenticated/signals',
        icon: 'fa-solid fa-sliders',
      },
      {
        title: 'Transactions & Funding',
        path: '/authenticated/transactions',
        icon: 'fa-solid fa-money-check-dollar',
      },
      {
        title: 'Reports',
        path: '/authenticated/reports',
        icon: 'fa-solid fa-file-invoice',
      },
    ],
  },
]

export default sidebarItems