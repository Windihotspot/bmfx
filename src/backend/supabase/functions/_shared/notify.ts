// _shared/notify.ts
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4'

/** In-app notification (delivered live through Supabase Realtime). Never throws. */
export async function notifyUser(
  admin: SupabaseClient,
  userId: string,
  n: { title: string; body?: string; type?: string; data?: Record<string, unknown> },
): Promise<void> {
  const { error } = await admin.from('notifications').insert({
    user_id: userId,
    title: n.title,
    body: n.body ?? null,
    type: n.type ?? 'info',
    data: n.data ?? {},
  })
  if (error) console.error('notification failed:', error.message)
}
