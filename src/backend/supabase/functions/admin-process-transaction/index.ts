// POST /functions/v1/admin-process-transaction   (admin)
// Body: { transactionId, action: 'approve' | 'reject', reason? }
// Approving a deposit credits the wallet. Approving a withdrawal pays out
// the locked funds. Rejecting a withdrawal releases the locked funds.

import { jsonResponse } from '../_shared/cors.ts'
import { createHandler, mapDbError, parseBody, z } from '../_shared/http.ts'
import { logAudit } from '../_shared/audit.ts'

const schema = z
  .object({
    transactionId: z.string().uuid(),
    action: z.enum(['approve', 'reject']),
    reason: z.string().trim().max(500).optional(),
  })
  .refine((d) => d.action === 'approve' || (d.reason && d.reason.length >= 3), {
    message: 'A reason is required when rejecting',
    path: ['reason'],
  })

Deno.serve(
  createHandler({ methods: ['POST'], auth: 'admin' }, async ({ req, admin, user, ip }) => {
    const input = await parseBody(req, schema)

    const { data: transaction, error } = await admin.rpc('admin_process_transaction', {
      p_tx_id: input.transactionId,
      p_admin_id: user.id,
      p_action: input.action,
      p_reason: input.reason ?? null,
    })
    if (error) throw mapDbError(error)

    await logAudit(admin, {
      actorId: user.id,
      action: `transaction.${input.action}`,
      entityType: 'wallet_transaction',
      entityId: transaction.id,
      metadata: { type: transaction.type, amount: transaction.amount, user_id: transaction.user_id, reason: input.reason ?? null },
      ip,
    })

    return jsonResponse({ transaction }, 200, req)
  }),
)
