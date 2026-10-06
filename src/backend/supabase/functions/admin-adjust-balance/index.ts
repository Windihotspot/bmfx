// POST /functions/v1/admin-adjust-balance   (super_admin)
// Body: { userId, amount (positive = credit, negative = debit), reason }
// Balance adjustments are sensitive, so they require super_admin.
// Change `auth: 'super_admin'` to `'admin'` below if regular admins should be allowed.

import { jsonResponse } from '../_shared/cors.ts'
import { createHandler, mapDbError, parseBody, z } from '../_shared/http.ts'
import { logAudit } from '../_shared/audit.ts'

const schema = z.object({
  userId: z.string().uuid(),
  amount: z
    .number()
    .refine((n) => n !== 0, 'Amount cannot be zero')
    .refine((n) => Math.abs(n) <= 10_000_000, 'Amount is too large'),
  reason: z.string().trim().min(5).max(300),
})

Deno.serve(
  createHandler({ methods: ['POST'], auth: 'super_admin' }, async ({ req, admin, user, ip }) => {
    const input = await parseBody(req, schema)

    const { data: transaction, error } = await admin.rpc('admin_adjust_balance', {
      p_admin_id: user.id,
      p_user_id: input.userId,
      p_amount: input.amount,
      p_reason: input.reason,
    })
    if (error) throw mapDbError(error)

    await logAudit(admin, {
      actorId: user.id,
      action: 'balance.adjusted',
      entityType: 'wallet_transaction',
      entityId: transaction.id,
      metadata: { user_id: input.userId, amount: input.amount, reason: input.reason },
      ip,
    })

    return jsonResponse({ transaction }, 200, req)
  }),
)
