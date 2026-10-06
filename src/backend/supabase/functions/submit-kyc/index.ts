// POST /functions/v1/submit-kyc
// Body: { documentType, documentNumber, frontPath, backPath?, selfiePath }
// Files must already be uploaded by the user to the `kyc-documents` bucket
// under their own folder: <userId>/<file>.

import { jsonResponse } from '../_shared/cors.ts'
import { createHandler, HttpError, mapDbError, parseBody, z } from '../_shared/http.ts'
import { logAudit } from '../_shared/audit.ts'
import { notifyUser } from '../_shared/notify.ts'

const path = z.string().min(3).max(300)

const schema = z.object({
  documentType: z.enum(['national_id', 'passport', 'drivers_license', 'voters_card']),
  documentNumber: z.string().trim().min(4).max(50),
  frontPath: path,
  backPath: path.optional(),
  selfiePath: path,
})

Deno.serve(
  createHandler({ methods: ['POST'], auth: 'user' }, async ({ req, admin, user, profile, ip }) => {
    const input = await parseBody(req, schema)

    const paths = [input.frontPath, input.selfiePath, input.backPath].filter(Boolean) as string[]
    if (paths.some((p) => !p.startsWith(`${user.id}/`) || p.includes('..'))) {
      throw new HttpError(400, 'Invalid file path')
    }
    if (profile.kyc_status === 'approved') throw new HttpError(409, 'Your identity is already verified')
    if (profile.kyc_status === 'pending') throw new HttpError(409, 'Your verification is already under review')

    const { data: submission, error } = await admin
      .from('kyc_submissions')
      .insert({
        user_id: user.id,
        document_type: input.documentType,
        document_number: input.documentNumber,
        front_path: input.frontPath,
        back_path: input.backPath ?? null,
        selfie_path: input.selfiePath,
        status: 'pending',
      })
      .select('id, status, created_at')
      .single()
    if (error) throw mapDbError(error)

    const { error: profileError } = await admin
      .from('profiles')
      .update({ kyc_status: 'pending' })
      .eq('id', user.id)
    if (profileError) throw profileError

    await Promise.all([
      logAudit(admin, { actorId: user.id, action: 'kyc.submitted', entityType: 'kyc_submission', entityId: submission.id, ip }),
      notifyUser(admin, user.id, {
        type: 'kyc',
        title: 'Verification submitted',
        body: 'We are reviewing your documents. This usually takes less than 24 hours.',
      }),
    ])

    return jsonResponse({ submission }, 201, req)
  }),
)
