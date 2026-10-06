// POST /functions/v1/request-deposit
// Body: { amount, paymentMethodId, proofPath?, note? }
// The user uploads their receipt to the `deposit-proofs` bucket first
// (path: <userId>/<file>) and passes that path as `proofPath`.
// The deposit stays "pending" until an admin approves it.

import { jsonResponse } from '../_shared/cors.ts'
import { createHandler, HttpError, mapDbError, parseBody, z } from '../_shared/http.ts'
import { logAudit } from '../_shared/audit.ts'

const schema = z.object({
  amount: z.number().positive().max(10_000_000),
  paymentMethodId: z.string().uuid(),
  proofPath: z.string().max(300).optional(),
  note: z.string().max(500).optional(),
})

Deno.serve(
  createHandler({ methods: ['POST'], auth: 'user' }, async ({ req, admin, user, ip }) => {
    const input = await parseBody(req, schema)

    if (input.proofPath && !input.proofPath.startsWith(`${user.id}/`)) {
      throw new HttpError(400, 'Invalid proof path')
    }

    const { data: method, error: methodError } = await admin
      .from('payment_methods')
      .select('id, name, min_amount, max_amount, is_active, is_deposit_enabled')
      .eq('id', input.paymentMethodId)
      .maybeSingle()
    if (methodError) throw methodError
    if (!method || !method.is_active || !method.is_deposit_enabled) {
      throw new HttpError(400, 'This payment method is not available for deposits')
    }
    if (input.amount < Number(method.min_amount)) {
      throw new HttpError(400, `Minimum deposit for ${method.name} is ${method.min_amount}`)
    }
    if (method.max_amount !== null && input.amount > Number(method.max_amount)) {
      throw new HttpError(400, `Maximum deposit for ${method.name} is ${method.max_amount}`)
    }

    const { data: transaction, error } = await admin.rpc('request_deposit', {
      p_user_id: user.id,
      p_amount: input.amount,
      p_method: method.name,
      p_details: { payment_method_id: method.id, note: input.note ?? null },
      p_proof_path: input.proofPath ?? null,
    })
    if (error) throw mapDbError(error)

    await logAudit(admin, {
      actorId: user.id,
      action: 'deposit.requested',
      entityType: 'wallet_transaction',
      entityId: transaction.id,
      metadata: { amount: transaction.amount, method: method.name },
      ip,
    })

    return jsonResponse({ transaction }, 201, req)
  }),
)
