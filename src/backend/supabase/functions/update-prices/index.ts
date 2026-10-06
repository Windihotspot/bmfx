// POST /functions/v1/update-prices
// Refreshes prices for every active asset whose price_provider is
// 'coingecko' or 'twelvedata'. Call it from pg_cron (see
// supabase/optional/cron_update_prices.sql) or by hand from the admin panel.
//
// Auth: header  x-cron-secret: <CRON_SECRET>   OR   an admin's access token.
// Deploy with --no-verify-jwt so the cron job does not need a user JWT.
//
// Secrets:  CRON_SECRET, TWELVE_DATA_API_KEY (stocks/forex/commodities),
//           COINGECKO_API_KEY (optional demo key), MAX_PRICE_JUMP_PCT (default 30)

import { jsonResponse } from '../_shared/cors.ts'
import { createOpenHandler, getRoles, HttpError, safeEqual } from '../_shared/http.ts'
import { getAuthenticatedUser } from '../_shared/supabaseAdmin.ts'

interface AssetRow {
  id: string
  symbol: string
  price: number
  price_provider: 'coingecko' | 'twelvedata'
  provider_symbol: string
}

const fetchJson = async (url: string, headers: Record<string, string> = {}) => {
  const res = await fetch(url, { headers, signal: AbortSignal.timeout(10_000) })
  if (!res.ok) throw new Error(`HTTP ${res.status} from ${new URL(url).host}`)
  return await res.json()
}

/** providerSymbol -> price */
async function fetchCoinGecko(symbols: string[]): Promise<Map<string, number>> {
  const out = new Map<string, number>()
  if (!symbols.length) return out
  const key = Deno.env.get('COINGECKO_API_KEY')
  const url = `https://api.coingecko.com/api/v3/simple/price?ids=${encodeURIComponent(symbols.join(','))}&vs_currencies=usd`
  const json = await fetchJson(url, key ? { 'x-cg-demo-api-key': key } : {})
  for (const s of symbols) {
    const p = Number(json?.[s]?.usd)
    if (p > 0) out.set(s, p)
  }
  return out
}

async function fetchTwelveData(symbols: string[]): Promise<Map<string, number>> {
  const out = new Map<string, number>()
  const key = Deno.env.get('TWELVE_DATA_API_KEY')
  if (!symbols.length) return out
  if (!key) throw new Error('TWELVE_DATA_API_KEY is not set')

  for (let i = 0; i < symbols.length; i += 8) {
    const chunk = symbols.slice(i, i + 8)
    const url = `https://api.twelvedata.com/price?symbol=${encodeURIComponent(chunk.join(','))}&apikey=${key}`
    const json = await fetchJson(url)
    // One symbol returns { price }, several return { SYMBOL: { price } }.
    const entries: [string, { price?: string }][] = chunk.length === 1 ? [[chunk[0], json]] : Object.entries(json)
    for (const [sym, v] of entries) {
      const p = Number(v?.price)
      if (p > 0) out.set(sym, p)
    }
  }
  return out
}

Deno.serve(
  createOpenHandler({ methods: ['POST', 'GET'] }, async ({ req, admin }) => {
    // ---- authorise: cron secret or admin user ----
    const secret = Deno.env.get('CRON_SECRET')
    const provided = req.headers.get('x-cron-secret')
    let allowed = !!(secret && provided && safeEqual(provided, secret))
    if (!allowed) {
      const user = await getAuthenticatedUser(req)
      if (user) {
        const roles = await getRoles(admin, user.id)
        allowed = roles.includes('admin') || roles.includes('super_admin')
      }
    }
    if (!allowed) throw new HttpError(401, 'Unauthorized')

    // ---- load assets that need automatic pricing ----
    const { data: assets, error } = await admin
      .from('assets')
      .select('id, symbol, price, price_provider, provider_symbol')
      .eq('is_active', true)
      .in('price_provider', ['coingecko', 'twelvedata'])
      .not('provider_symbol', 'is', null)
    if (error) throw error

    const rows = (assets ?? []) as AssetRow[]
    const bySymbol = (p: string) => [...new Set(rows.filter((a) => a.price_provider === p).map((a) => a.provider_symbol))]

    const failures: { symbol: string; reason: string }[] = []
    const prices = new Map<string, Map<string, number>>()
    for (const [provider, fetcher] of [['coingecko', fetchCoinGecko], ['twelvedata', fetchTwelveData]] as const) {
      try {
        prices.set(provider, await fetcher(bySymbol(provider)))
      } catch (e) {
        prices.set(provider, new Map())
        rows.filter((a) => a.price_provider === provider)
          .forEach((a) => failures.push({ symbol: a.symbol, reason: (e as Error).message }))
      }
    }

    // ---- apply, with a sanity guard against bad data ----
    const maxJump = Number(Deno.env.get('MAX_PRICE_JUMP_PCT') ?? '30')
    const updated: string[] = []

    await Promise.all(rows.map(async (a) => {
      if (failures.some((f) => f.symbol === a.symbol)) return
      const price = prices.get(a.price_provider)?.get(a.provider_symbol)
      if (!price) {
        failures.push({ symbol: a.symbol, reason: 'No price returned by provider' })
        return
      }
      if (a.price > 0 && (Math.abs(price - a.price) / a.price) * 100 > maxJump) {
        failures.push({ symbol: a.symbol, reason: `Price moved more than ${maxJump}% (${a.price} -> ${price}); skipped, review manually` })
        return
      }
      const { error: rpcError } = await admin.rpc('apply_asset_price', {
        p_asset_id: a.id,
        p_price: price,
        p_record_history: true,
      })
      if (rpcError) failures.push({ symbol: a.symbol, reason: rpcError.message })
      else updated.push(a.symbol)
    }))

    return jsonResponse({ updated, failed: failures, checked: rows.length }, 200, req)
  }),
)
