// POST /functions/v1/request-withdrawal
// Body: { amount, paymentMethodId, destination: { ...key/value strings } }
//   e.g. destination: { bankName, accountName, accountNumber }
//        destination: { network: 'TRC20', address: '...' }
// Funds are reserved immediately (moved to locked_balance) and released
// or paid out when an admin processes the request. Requires approved KYC.

import { jsonResponse } from '../_shared/cors.ts'
import { createHandler, HttpError, mapDbError, parseBody, z } from '../_shared/http.ts'
import { logAudit } from '../_shared/audit.ts'

const schema = z.object({
  amount: z.number().positive().max(10_000_000),
  paymentMethodId: z.string().uuid(),
  destination: z
    .record(z.string().trim().min(1).max(200))
    .refine((d) => Object.keys(d).length >= 1 && Object.keys(d).length <= 10, {
      message: 'Provide between 1 and 10 destination fields',
    }),
})

Deno.serve(
  createHandler({ methods: ['POST'], auth: 'user' }, async ({ req, admin, user, ip }) => {
    const input = await parseBody(req, schema)

    const { data: method, error: methodError } = await admin
      .from('payment_methods')
      .select('id, name, min_amount, max_amount, is_active, is_withdrawal_enabled')
      .eq('id', input.paymentMethodId)
      .maybeSingle()
    if (methodError) throw methodError
    if (!method || !method.is_active || !method.is_withdrawal_enabled) {
      throw new HttpError(400, 'This payment method is not available for withdrawals')
    }
    if (method.max_amount !== null && input.amount > Number(method.max_amount)) {
      throw new HttpError(400, `Maximum withdrawal for ${method.name} is ${method.max_amount}`)
    }

    const { data: transaction, error } = await admin.rpc('request_withdrawal', {
      p_user_id: user.id,
      p_amount: input.amount,
      p_method: method.name,
      p_details: { payment_method_id: method.id, destination: input.destination },
    })
    if (error) throw mapDbError(error)

    await logAudit(admin, {
      actorId: user.id,
      action: 'withdrawal.requested',
      entityType: 'wallet_transaction',
      entityId: transaction.id,
      metadata: { amount: transaction.amount, fee: transaction.fee, method: method.name },
      ip,
    })

    return jsonResponse({ transaction }, 201, req)
  }),
)
