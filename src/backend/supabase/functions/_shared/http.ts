// _shared/http.ts
// Request pipeline shared by every edge function:
//   CORS preflight -> method check -> authentication -> role check
//   -> your handler -> uniform error handling.
//
// Depends on your existing helpers:
//   ./cors.ts           (handleCors, jsonResponse, errorResponse)
//   ./supabaseAdmin.ts  (getAdminClient, getAuthenticatedUser)

import { z, type ZodTypeAny } from 'https://esm.sh/zod@3.23.8'
import type { SupabaseClient, User } from 'https://esm.sh/@supabase/supabase-js@2.45.4'
import { errorResponse, handleCors } from './cors.ts'
import { getAdminClient, getAuthenticatedUser } from './supabaseAdmin.ts'

export { z }

export class HttpError extends Error {
  constructor(public status: number, message: string, public details?: unknown) {
    super(message)
  }
}

export type AuthLevel = 'user' | 'admin' | 'super_admin'

export interface Profile {
  id: string
  email: string
  first_name: string
  last_name: string
  is_active: boolean
  kyc_status: 'not_submitted' | 'pending' | 'approved' | 'rejected'
}

export interface Ctx {
  req: Request
  admin: SupabaseClient
  user: User
  profile: Profile
  roles: string[]
  ip: string | null
}

export interface OpenCtx {
  req: Request
  admin: SupabaseClient
  ip: string | null
}

const clientIp = (req: Request) =>
  req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? null

export async function getRoles(admin: SupabaseClient, userId: string): Promise<string[]> {
  const { data, error } = await admin.from('user_roles').select('role').eq('user_id', userId)
  if (error) throw error
  return (data ?? []).map((r) => r.role as string)
}

/** Parses and validates a JSON body. Throws a 422 with field errors. */
export async function parseBody<T extends ZodTypeAny>(req: Request, schema: T): Promise<z.infer<T>> {
  let raw: unknown
  try {
    raw = await req.json()
  } catch {
    throw new HttpError(400, 'Request body must be valid JSON')
  }
  const result = schema.safeParse(raw)
  if (!result.success) throw new HttpError(422, 'Validation failed', result.error.flatten())
  return result.data
}

/**
 * Converts a Postgres/PostgREST error into an HttpError.
 * Business-rule failures raised by our SQL functions use SQLSTATE P0001,
 * so their message is safe to show the user. Anything else stays private.
 */
export function mapDbError(error: { code?: string; message: string }): HttpError {
  if (error.code === 'P0001') return new HttpError(400, error.message)
  if (error.code === '23505') return new HttpError(409, 'This record already exists')
  console.error('Database error:', error)
  return new HttpError(500, 'Internal server error')
}

/** Constant-time string comparison (for shared secrets). */
export function safeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder()
  const x = enc.encode(a)
  const y = enc.encode(b)
  let diff = x.length ^ y.length
  for (let i = 0; i < Math.max(x.length, y.length); i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0)
  return diff === 0
}

function wrap(methods: string[], run: (req: Request) => Promise<Response>) {
  return async (req: Request): Promise<Response> => {
    const preflight = handleCors(req)
    if (preflight) return preflight
    try {
      if (!methods.includes(req.method)) {
        return errorResponse('Method not allowed', 405, undefined, req)
      }
      return await run(req)
    } catch (e) {
      if (e instanceof HttpError) return errorResponse(e.message, e.status, e.details, req)
      console.error('Unhandled error:', e)
      return errorResponse('Internal server error', 500, undefined, req)
    }
  }
}

/** Handler for signed-in users. `auth` sets the minimum role required. */
export function createHandler(
  opts: { methods: string[]; auth: AuthLevel },
  fn: (ctx: Ctx) => Promise<Response>,
) {
  return wrap(opts.methods, async (req) => {
    const user = await getAuthenticatedUser(req)
    if (!user) throw new HttpError(401, 'Unauthorized')

    const admin = getAdminClient()
    const { data: profile, error } = await admin
      .from('profiles')
      .select('id, email, first_name, last_name, is_active, kyc_status')
      .eq('id', user.id)
      .maybeSingle()
    if (error) throw error
    if (!profile) throw new HttpError(403, 'Profile not found')
    if (!profile.is_active) throw new HttpError(403, 'Your account has been deactivated')

    const roles = await getRoles(admin, user.id)
    const isAdmin = roles.includes('admin') || roles.includes('super_admin')
    if (opts.auth === 'admin' && !isAdmin) throw new HttpError(403, 'Admin access required')
    if (opts.auth === 'super_admin' && !roles.includes('super_admin')) {
      throw new HttpError(403, 'Super admin access required')
    }

    return await fn({ req, admin, user, profile: profile as Profile, roles, ip: clientIp(req) })
  })
}

/** Handler that does its own authentication (cron jobs, webhooks, public endpoints). */
export function createOpenHandler(
  opts: { methods: string[] },
  fn: (ctx: OpenCtx) => Promise<Response>,
) {
  return wrap(opts.methods, (req) => fn({ req, admin: getAdminClient(), ip: clientIp(req) }))
}
