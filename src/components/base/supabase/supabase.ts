// src/supabaseClient.ts
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://ymlauupogmuhdnitwtcq.supabase.co'
const supabaseKey =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InltbGF1dXBvZ211aGRuaXR3dGNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTc1ODg0NjcsImV4cCI6MjAzMzE2NDQ2N30.KueoYn-hsc4o89w1I2EC_q8B1nNzgzUI0O_QSwBOxIQ'
export const supabase = createClient(supabaseUrl, supabaseKey)
