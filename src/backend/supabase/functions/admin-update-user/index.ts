// POST /functions/v1/admin-update-user   (admin; role changes need super_admin)
// Body: { userId, isActive?, grantRole?: 'admin', revokeRole?: 'admin' }
// Deactivating a user also bans them in Supabase Auth so existing sessions
// stop working once their access token expires.

import { jsonResponse } from '../_shared/cors.ts'
import { createHandler, HttpError, parseBody, z } from '../_shared/http.ts'
import { logAudit } from '../_shared/audit.ts'

const schema = z
  .object({
    userId: z.string().uuid(),
    isActive: z.boolean().optional(),
    grantRole: z.enum(['admin']).optional(),
    revokeRole: z.enum(['admin']).optional(),
  })
  .refine((d) => d.isActive !== undefined || d.grantRole || d.revokeRole, {
    message: 'Nothing to update',
  })

Deno.serve(
  createHandler({ methods: ['POST'], auth: 'admin' }, async ({ req, admin, user, roles, ip }) => {
    const input = await parseBody(req, schema)
    const isSuper = roles.includes('super_admin')

    if (input.userId === user.id && input.isActive === false) {
      throw new HttpError(400, 'You cannot deactivate your own account')
    }
    if ((input.grantRole || input.revokeRole) && !isSuper) {
      throw new HttpError(403, 'Only a super admin can change roles')
    }

    const { data: target } = await admin.from('profiles').select('id').eq('id', input.userId).maybeSingle()
    if (!target) throw new HttpError(404, 'User not found')

    if (input.isActive !== undefined) {
      const { error } = await admin.from('profiles').update({ is_active: input.isActive }).eq('id', input.userId)
      if (error) throw error
      const { error: banError } = await admin.auth.admin.updateUserById(input.userId, {
        ban_duration: input.isActive ? 'none' : '876000h',
      })
      if (banError) throw banError
    }
    if (input.grantRole) {
      const { error } = await admin
        .from('user_roles')
        .upsert({ user_id: input.userId, role: input.grantRole }, { onConflict: 'user_id,role' })
      if (error) throw error
    }
    if (input.revokeRole) {
      const { error } = await admin.from('user_roles').delete().eq('user_id', input.userId).eq('role', input.revokeRole)
      if (error) throw error
    }

    await logAudit(admin, {
      actorId: user.id,
      action: 'user.updated',
      entityType: 'user',
      entityId: input.userId,
      metadata: { isActive: input.isActive, grantRole: input.grantRole, revokeRole: input.revokeRole },
      ip,
    })

    return jsonResponse({ ok: true }, 200, req)
  }),
)
