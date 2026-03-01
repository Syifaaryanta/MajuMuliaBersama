# SERVER — Supabase Configuration & Database Schema

Folder ini berisi semua hal yang berkaitan dengan **Supabase** sebagai backend:

```
server/
├── schema/
│   ├── 00_profiles.sql       ← Tabel user profile & role
│   ├── 01_customers.sql      ← Tabel customer + limit kredit
│   ├── 02_suppliers.sql      ← Tabel supplier
│   ├── 03_products.sql       ← Tabel barang (stok, harga, foto)
│   ├── 04_purchase_orders.sql ← Tabel PO pembelian (2-tahap)
│   ├── 05_sales.sql          ← Tabel penjualan + item
│   └── 06_payments.sql       ← Tabel pembayaran / pelunasan piutang
└── README.md                 ← File ini
```

## Cara Setup Supabase

1. Buka [https://supabase.com](https://supabase.com) → Login → Buka project Anda.
2. Masuk ke **SQL Editor**.
3. Jalankan file `.sql` di folder `schema/` **secara berurutan** (mulai dari `00_` dst).
4. Salin **Project URL** dan **anon/public Key** dari menu **Settings → API**.
5. Paste ke file `.env` di root project:
   ```
   VITE_SUPABASE_URL=https://xxxx.supabase.co
   VITE_SUPABASE_ANON_KEY=eyJhbGci...
   ```

## User Roles

| Role          | Deskripsi                                      |
|---------------|------------------------------------------------|
| `admin`       | Akses penuh, approval harga, semua laporan     |
| `staff_gudang`| Input pembelian, validasi barang masuk         |
| `staff_kantor`| Input penjualan, cetak invoice                 |
| `sales`       | View-only: cek stok, harga, piutang            |

## Catatan Penting: Row Level Security (RLS)

Semua tabel menggunakan **RLS (Row Level Security)** di Supabase.
Akses data dikontrol berdasarkan `role` di tabel `profiles`.
