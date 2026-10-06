// POST /functions/v1/admin-review-kyc   (admin)
// Body: { submissionId, action: 'approve' | 'reject', notes? }
// To view the uploaded documents, admins create signed URLs from the
// browser (storage policies allow admins to read the kyc-documents bucket).

import { jsonResponse } from '../_shared/cors.ts'
import { createHandler, HttpError, parseBody, z } from '../_shared/http.ts'
import { logAudit } from '../_shared/audit.ts'
import { notifyUser } from '../_shared/notify.ts'

const schema = z
  .object({
    submissionId: z.string().uuid(),
    action: z.enum(['approve', 'reject']),
    notes: z.string().trim().max(500).optional(),
  })
  .refine((d) => d.action === 'approve' || (d.notes && d.notes.length >= 3), {
    message: 'Notes are required when rejecting',
    path: ['notes'],
  })

Deno.serve(
  createHandler({ methods: ['POST'], auth: 'admin' }, async ({ req, admin, user, ip }) => {
    const input = await parseBody(req, schema)
    const status = input.action === 'approve' ? 'approved' : 'rejected'

    // The status filter makes this safe against two admins reviewing at once.
    const { data: submission, error } = await admin
      .from('kyc_submissions')
      .update({
        status,
        review_notes: input.notes ?? null,
        reviewed_by: user.id,
        reviewed_at: new Date().toISOString(),
      })
      .eq('id', input.submissionId)
      .eq('status', 'pending')
      .select('id, user_id, status')
      .maybeSingle()
    if (error) throw error
    if (!submission) throw new HttpError(404, 'Pending submission not found')

    const { error: profileError } = await admin
      .from('profiles')
      .update({ kyc_status: status })
      .eq('id', submission.user_id)
    if (profileError) throw profileError

    await Promise.all([
      logAudit(admin, {
        actorId: user.id,
        action: `kyc.${status}`,
        entityType: 'kyc_submission',
        entityId: submission.id,
        metadata: { user_id: submission.user_id, notes: input.notes ?? null },
        ip,
      }),
      notifyUser(admin, submission.user_id, {
        type: 'kyc',
        title: status === 'approved' ? 'Identity verified' : 'Verification unsuccessful',
        body: status === 'approved'
          ? 'Your identity has been verified. You can now withdraw funds.'
          : `We could not verify your documents. ${input.notes ?? ''} Please submit again.`,
      }),
    ])

    return jsonResponse({ submission }, 200, req)
  }),
)
