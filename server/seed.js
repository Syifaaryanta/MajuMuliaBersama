/**
 * server/seed.js
 * ============================================================
 * Script untuk membuat 3 akun user awal + setup RBAC di Supabase.
 *
 * LANGKAH SEBELUM MENJALANKAN:
 *  1. Jalankan server/schema/01_schema.sql di Supabase SQL Editor.
 *  2. Isi SUPABASE_SERVICE_ROLE_KEY di file .env
 *     (Supabase Dashboard → Settings → API → service_role)
 *
 * CARA JALANKAN:
 *  node --env-file=.env server/seed.js
 * ============================================================
 */

import { createClient } from '@supabase/supabase-js'

// ============================================================
// Validasi env
// ============================================================
const SUPABASE_URL      = process.env.VITE_SUPABASE_URL
const SERVICE_ROLE_KEY  = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  console.error('\n[ERROR] Environment variable belum lengkap.')
  console.error('  VITE_SUPABASE_URL      :', SUPABASE_URL ? '✓' : '✗ KOSONG')
  console.error('  SUPABASE_SERVICE_ROLE_KEY:', SERVICE_ROLE_KEY ? '✓' : '✗ KOSONG')
  console.error('\nIsi .env terlebih dahulu, lalu jalankan ulang.\n')
  process.exit(1)
}

// ============================================================
// Admin Supabase client (service_role — bypass RLS)
// ============================================================
const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false }
})

// ============================================================
// Daftar user yang akan dibuat
// Format password: "nama"123
// ============================================================
const USERS = [
  {
    email    : 'admin@mmb.com',
    password : 'admin123',
    nama     : 'Admin MMB',
    role     : 'admin',
  },
  {
    email    : 'gudang@mmb.com',
    password : 'gudang123',
    nama     : 'Staff Gudang',
    role     : 'staff_gudang',
  },
  {
    email    : 'sales@mmb.com',
    password : 'sales123',
    nama     : 'Sales Lapangan',
    role     : 'sales',
  },
  {
    email    : 'kantor@mmb.com',
    password : 'kantor123',
    nama     : 'Staff Kantor',
    role     : 'staff_kantor',
  },
]

// ============================================================
// Helper
// ============================================================
const RESET  = '\x1b[0m'
const GREEN  = '\x1b[32m'
const RED    = '\x1b[31m'
const YELLOW = '\x1b[33m'
const CYAN   = '\x1b[36m'
const BOLD   = '\x1b[1m'

function ok(msg)   { console.log(`  ${GREEN}✓${RESET} ${msg}`) }
function fail(msg) { console.log(`  ${RED}✗${RESET} ${msg}`) }
function info(msg) { console.log(`  ${YELLOW}→${RESET} ${msg}`) }

// ============================================================
// Main
// ============================================================
async function seed() {
  console.log(`\n${BOLD}${CYAN}MMB — Supabase Seed Script${RESET}`)
  console.log(`${'─'.repeat(48)}`)
  console.log(`Target: ${SUPABASE_URL}\n`)

  let successCount = 0
  let skipCount    = 0
  let errorCount   = 0

  for (const user of USERS) {
    console.log(`${BOLD}[${user.role.toUpperCase()}]${RESET} ${user.email}`)

    // ── 1. Cek apakah user sudah ada ──────────────────────
    const { data: existingList } = await supabase.auth.admin.listUsers()
    const existing = existingList?.users?.find(u => u.email === user.email)

    let userId

    if (existing) {
      info(`User sudah ada, skip pembuatan akun.`)
      userId = existing.id
      skipCount++
    } else {
      // ── 2. Buat user baru ──────────────────────────────
      const { data, error } = await supabase.auth.admin.createUser({
        email             : user.email,
        password          : user.password,
        email_confirm     : true,      // langsung confirmed, tidak perlu verif email
        user_metadata     : {
          nama : user.nama,
          role : user.role,
        },
      })

      if (error) {
        fail(`Gagal buat user: ${error.message}`)
        errorCount++
        console.log()
        continue
      }

      ok(`Akun dibuat (${data.user.id.slice(0, 8)}...)`)
      userId = data.user.id
      successCount++
    }

    // ── 3. Upsert profile dengan role yang benar ──────────
    const { error: profileError } = await supabase
      .from('profiles')
      .upsert(
        { id: userId, email: user.email, nama: user.nama, role: user.role, aktif: true },
        { onConflict: 'id' }
      )

    if (profileError) {
      fail(`Gagal upsert profile: ${profileError.message}`)
      if (profileError.message.includes('does not exist')) {
        console.log()
        console.error(`\n${RED}${BOLD}[PENTING] Tabel 'profiles' belum ada!${RESET}`)
        console.error(`Jalankan dulu SQL ini di Supabase Dashboard > SQL Editor:`)
        console.error(`  ${CYAN}server/schema/01_schema.sql${RESET}\n`)
        process.exit(1)
      }
    } else {
      ok(`Profile & role (${user.role}) berhasil di-set`)
    }

    console.log()
  }

  // ── Ringkasan ──────────────────────────────────────────
  console.log(`${'─'.repeat(48)}`)
  console.log(`${BOLD}Selesai!${RESET}`)
  console.log(`  ${GREEN}Dibuat baru : ${successCount}${RESET}`)
  console.log(`  ${YELLOW}Sudah ada   : ${skipCount}${RESET}`)
  if (errorCount > 0)
    console.log(`  ${RED}Error       : ${errorCount}${RESET}`)

  console.log(`\n${BOLD}Akun tersedia:${RESET}`)
  for (const u of USERS) {
    console.log(`  ${CYAN}${u.email.padEnd(22)}${RESET}  pass: ${u.password.padEnd(12)}  role: ${u.role}`)
  }
  console.log()
}

seed().catch(err => {
  console.error('\n[FATAL]', err.message)
  process.exit(1)
})
