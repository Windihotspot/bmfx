// _shared/audit.ts
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4'

export interface AuditEntry {
  actorId: string | null
  action: string
  entityType?: string
  entityId?: string
  metadata?: Record<string, unknown>
  ip?: string | null
}

/** Writes to audit_logs. Never throws: auditing must not break the request. */
export async function logAudit(admin: SupabaseClient, e: AuditEntry): Promise<void> {
  const { error } = await admin.from('audit_logs').insert({
    actor_id: e.actorId,
    action: e.action,
    entity_type: e.entityType ?? null,
    entity_id: e.entityId ?? null,
    metadata: e.metadata ?? {},
    ip_address: e.ip ?? null,
  })
  if (error) console.error('audit log failed:', error.message)
}
