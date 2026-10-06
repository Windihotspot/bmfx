// POST /functions/v1/place-order
// Body: { assetId, side: 'buy' | 'sell', quantity? | amount?, clientOrderId? }
//   buy  -> `amount` (USD to spend) or `quantity` (units to buy)
//   sell -> `quantity` (units to sell) or `amount` (USD worth to sell)
// `clientOrderId` makes retries safe: the same id returns the original order.

import { jsonResponse } from '../_shared/cors.ts'
import { createHandler, mapDbError, parseBody, z } from '../_shared/http.ts'
import { logAudit } from '../_shared/audit.ts'
import { notifyUser } from '../_shared/notify.ts'

const schema = z
  .object({
    assetId: z.string().uuid(),
    side: z.enum(['buy', 'sell']),
    quantity: z.number().positive().max(1e12).optional(),
    amount: z.number().positive().max(1e9).optional(),
    clientOrderId: z.string().min(8).max(64).optional(),
  })
  .refine((d) => (d.quantity === undefined) !== (d.amount === undefined), {
    message: 'Provide either quantity or amount, not both',
  })

Deno.serve(
  createHandler({ methods: ['POST'], auth: 'user' }, async ({ req, admin, user, ip }) => {
    const input = await parseBody(req, schema)

    const { data: order, error } = await admin.rpc('execute_trade', {
      p_user_id: user.id,
      p_asset_id: input.assetId,
      p_side: input.side,
      p_quantity: input.quantity ?? null,
      p_amount: input.amount ?? null,
      p_client_order_id: input.clientOrderId ?? null,
    })
    if (error) throw mapDbError(error)

    await Promise.all([
      logAudit(admin, {
        actorId: user.id,
        action: 'order.placed',
        entityType: 'order',
        entityId: order.id,
        metadata: { side: order.side, quantity: order.quantity, price: order.price },
        ip,
      }),
      notifyUser(admin, user.id, {
        type: 'trade',
        title: `${order.side === 'buy' ? 'Buy' : 'Sell'} order filled`,
        body: `${order.quantity} units at ${order.price} (total ${order.net_amount}).`,
        data: { order_id: order.id },
      }),
    ])

    return jsonResponse({ order }, 201, req)
  }),
)
