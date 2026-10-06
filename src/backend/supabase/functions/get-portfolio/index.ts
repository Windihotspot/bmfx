// GET /functions/v1/get-portfolio
// Returns { wallet, holdings[], summary } valued at current prices.

import { jsonResponse } from '../_shared/cors.ts'
import { createHandler, mapDbError } from '../_shared/http.ts'

Deno.serve(
  createHandler({ methods: ['GET', 'POST'], auth: 'user' }, async ({ req, admin, user }) => {
    const { data, error } = await admin.rpc('get_portfolio', { p_user_id: user.id })
    if (error) throw mapDbError(error)
    return jsonResponse(data, 200, req)
  }),
)
