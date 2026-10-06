// POST /functions/v1/admin-upsert-asset   (admin)
// Create or edit a tradable asset. Pass `id` to edit.
// For assets with priceProvider 'manual', send `price` to set the price.

import { jsonResponse } from '../_shared/cors.ts'
import { createHandler, HttpError, mapDbError, parseBody, z } from '../_shared/http.ts'
import { logAudit } from '../_shared/audit.ts'

const schema = z
  .object({
    id: z.string().uuid().optional(),
    symbol: z.string().trim().toUpperCase().min(1).max(20).regex(/^[A-Z0-9._-]+$/),
    name: z.string().trim().min(1).max(100),
    assetClass: z.enum(['stock', 'forex', 'crypto', 'commodity', 'index', 'etf']),
    priceProvider: z.enum(['manual', 'coingecko', 'twelvedata']).default('manual'),
    providerSymbol: z.string().trim().max(50).nullable().optional(),
    price: z.number().positive().optional(),
    quantityDecimals: z.number().int().min(0).max(8).default(8),
    minOrderAmount: z.number().min(0).default(1),
    logoUrl: z.string().url().nullable().optional(),
    isActive: z.boolean().default(true),
    isTradable: z.boolean().default(true),
  })
  .refine((d) => d.priceProvider === 'manual' || !!d.providerSymbol, {
    message: 'providerSymbol is required for automatic price providers',
    path: ['providerSymbol'],
  })

Deno.serve(
  createHandler({ methods: ['POST'], auth: 'admin' }, async ({ req, admin, user, ip }) => {
    const input = await parseBody(req, schema)

    const row = {
      symbol: input.symbol,
      name: input.name,
      asset_class: input.assetClass,
      price_provider: input.priceProvider,
      provider_symbol: input.priceProvider === 'manual' ? null : input.providerSymbol,
      quantity_decimals: input.quantityDecimals,
      min_order_amount: input.minOrderAmount,
      logo_url: input.logoUrl ?? null,
      is_active: input.isActive,
      is_tradable: input.isTradable,
    }

    const query = input.id
      ? admin.from('assets').update(row).eq('id', input.id)
      : admin.from('assets').insert(row)
    const { data: asset, error } = await query.select('*').maybeSingle()
    if (error) throw mapDbError(error)
    if (!asset) throw new HttpError(404, 'Asset not found')

    let result = asset
    if (input.price !== undefined) {
      const { data, error: priceError } = await admin.rpc('apply_asset_price', {
        p_asset_id: asset.id,
        p_price: input.price,
        p_record_history: true,
      })
      if (priceError) throw mapDbError(priceError)
      result = data
    }

    await logAudit(admin, {
      actorId: user.id,
      action: input.id ? 'asset.updated' : 'asset.created',
      entityType: 'asset',
      entityId: asset.id,
      metadata: { symbol: asset.symbol, price: input.price ?? null },
      ip,
    })

    return jsonResponse({ asset: result }, input.id ? 200 : 201, req)
  }),
)
