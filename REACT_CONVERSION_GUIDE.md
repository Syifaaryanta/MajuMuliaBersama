# 📘 Panduan Konversi MMB System ke React/JSX

> **Sistem Inventori & POS - Maju Mulia Bersama (MMB)**  
> Konversi dari Vue 3 + Pinia ke React 18 + Context API/Zustand

---

## 📋 Table of Contents

1. [Overview Sistem](#overview-sistem)
2. [Struktur Database](#struktur-database)
3. [Fitur-Fitur Aplikasi](#fitur-fitur-aplikasi)
4. [Tech Stack Conversion](#tech-stack-conversion)
5. [Rencana Konversi](#rencana-konversi)

---

## 🎯 Overview Sistem

**MMB (Maju Mulia Bersama)** adalah sistem manajemen inventori dan Point of Sale (POS) untuk bisnis sparepart AC mobil dengan fitur:

- ✅ Manajemen Stok Real-time
- ✅ Pencatatan Piutang Otomatis  
- ✅ Laporan Keuangan Lengkap
- ✅ Role-Based Access Control (RBAC)
- ✅ Multi-user dengan 4 role berbeda

---

## 🗄️ Struktur Database

### **Backend:** Supabase (PostgreSQL + Authentication + RLS)

### **Tables:**

#### 1. **profiles** (User Management)
```sql
- id: UUID (FK ke auth.users)
- email: TEXT
- nama: TEXT
- role: ENUM ('admin', 'staff_gudang', 'staff_kantor', 'sales')
- aktif: BOOLEAN
- created_at, updated_at: TIMESTAMPTZ
```

#### 2. **products** (Barang)
```sql
- id: UUID
- kode: TEXT (unique)
- nama: TEXT
- deskripsi: TEXT
- stok: INTEGER
- satuan: TEXT (default: 'pcs')
- aktif: BOOLEAN
- foto_urls: TEXT[] (array URL foto)
- created_at, updated_at: TIMESTAMPTZ
```

#### 3. **suppliers** (Pemasok)
```sql
- id: UUID
- kode: TEXT (unique, auto: S001, S002...)
- nama: TEXT
- alamat: TEXT
- no_telp: TEXT
- aktif: BOOLEAN
- created_at, updated_at: TIMESTAMPTZ
```

#### 4. **customers** (Pelanggan)
```sql
- id: UUID
- kode: TEXT (unique, auto: C001, C002...)
- nama: TEXT
- alamat: TEXT
- no_telp: TEXT
- limit_kredit: NUMERIC(15,2) (default: 10,000,000)
- saldo_piutang: NUMERIC(15,2)
- aktif: BOOLEAN
- created_at, updated_at: TIMESTAMPTZ
```

#### 5. **product_prices** (Harga Barang per Supplier)
```sql
- id: UUID
- product_id: UUID (FK products)
- supplier_id: UUID (FK suppliers)
- stok: INTEGER
- harga_beli: NUMERIC(15,2)
- aktif: BOOLEAN
- updated_at: TIMESTAMPTZ
- UNIQUE(product_id, supplier_id)
```

#### 6. **purchases** (Pembelian/Nota Beli)
```sql
- id: UUID
- no_purchase: TEXT (auto: PB-YYYYMMDD-XXX)
- supplier_id: UUID
- purchase_date: DATE
- total: NUMERIC(15,2)
- catatan: TEXT
- status: TEXT
- created_by: UUID
- created_at, updated_at: TIMESTAMPTZ
```

#### 7. **purchase_items** (Detail Item Pembelian)
```sql
- id: UUID
- purchase_id: UUID (FK purchases)
- product_id: UUID (FK products)
- qty: INTEGER
- harga_beli: NUMERIC(15,2)
- subtotal: NUMERIC(15,2)
```

#### 8. **sales** (Penjualan/Nota Jual)
```sql
- id: UUID
- no_order: TEXT (auto: SO-YYYYMMDD-XXX)
- order_date: DATE
- customer_id: UUID
- customer_nama: TEXT
- customer_alamat: TEXT
- customer_telp: TEXT
- diantar: BOOLEAN (true=diantar, false=diambil)
- limit_bulan: INTEGER (0=1bln, 1=2bln, 2=3bln)
- salesman: TEXT (A, B, C, D, E)
- subtotal: NUMERIC(15,2)
- status: TEXT ('draft', 'completed')
- created_by: UUID
- created_at, updated_at: TIMESTAMPTZ
```

#### 9. **sale_items** (Detail Item Penjualan)
```sql
- id: UUID
- sale_id: UUID (FK sales)
- product_id: UUID (FK products)
- qty: INTEGER
- harga_jual: NUMERIC(15,2)
- harga_beli: NUMERIC(15,2)
- subtotal: NUMERIC(15,2)
```

---

## 🔐 RBAC (Role-Based Access Control)

### **4 Role User:**

#### 1. **admin** - Full Access
- ✅ Dashboard
- ✅ Gudang (CRUD)
- ✅ Pembelian (CRUD)
- ✅ Penjualan (CRUD)
- ✅ Penagihan (CRUD)
- ✅ Laporan (View)
- ✅ Master Data (CRUD)

#### 2. **staff_gudang** - Inventory Management
- ✅ Dashboard
- ✅ Gudang (CRUD)
- ✅ Master Data (View)

#### 3. **sales** - Sales & Collection
- ✅ Dashboard
- ✅ Pembelian (CRUD)
- ✅ Penjualan (CRUD)
- ✅ Penagihan (CRUD)
- ✅ Master Data (View)

#### 4. **staff_kantor** - Read-Only Access
- ✅ Dashboard
- ✅ Gudang (View)
- ✅ Pembelian (View)
- ✅ Penjualan (View)
- ✅ Penagihan (View)
- ✅ Laporan (View)
- ✅ Master Data (View)

### **RLS (Row Level Security) di Supabase:**
```sql
-- Helper function untuk check role
CREATE FUNCTION get_my_role() RETURNS TEXT AS $$
  SELECT role::TEXT FROM profiles WHERE id = auth.uid();
$$;

-- Policy examples:
-- User login bisa baca semua data
CREATE POLICY "User login bisa baca" ON products
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Admin & gudang bisa kelola produk
CREATE POLICY "Admin & gudang bisa kelola" ON products
  FOR ALL USING (get_my_role() IN ('admin', 'staff_gudang'));
```

---

## 🎨 Fitur-Fitur Aplikasi

### 1. 🔑 **Login & Authentication**

**Current (Vue):**
```vue
<template>
  <form @submit.prevent="handleLogin">
    <input v-model="form.email" type="email" />
    <input v-model="form.password" type="password" />
    <button :disabled="authStore.loading">Login</button>
  </form>
</template>

<script setup>
import { useAuthStore } from '@/stores/auth'
const authStore = useAuthStore()

async function handleLogin() {
  await authStore.login(form.email, form.password)
  router.push('/dashboard')
}
</script>
```

**React Conversion:**
```jsx
// src/contexts/AuthContext.jsx
import { createContext, useContext, useState } from 'react';
import { supabase } from '../lib/supabase';

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(false);

  async function login(email, password) {
    setLoading(true);
    try {
      const { data, error } = await supabase.auth.signInWithPassword({ 
        email, 
        password 
      });
      if (error) throw error;
      setUser(data.user);
      await fetchProfile(data.user.id);
      return data;
    } finally {
      setLoading(false);
    }
  }

  async function fetchProfile(userId) {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();
    setProfile(data);
  }

  async function logout() {
    await supabase.auth.signOut();
    setUser(null);
    setProfile(null);
  }

  return (
    <AuthContext.Provider value={{ user, profile, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
```

```jsx
// src/pages/LoginPage.jsx
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const { login, loading } = useAuth();
  const navigate = useNavigate();

  async function handleSubmit(e) {
    e.preventDefault();
    try {
      await login(email, password);
      navigate('/dashboard');
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <div className="login-wrapper">
      <div className="login-left">
        <div className="brand-content">
          <h1>Maju Mulia Bersama</h1>
          <p>Sistem Inventori & POS</p>
        </div>
      </div>
      
      <div className="login-right">
        <form onSubmit={handleSubmit}>
          <h2>Selamat Datang</h2>
          
          <div className="field-group">
            <label>Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="email@perusahaan.com"
            />
          </div>

          <div className="field-group">
            <label>Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
            />
          </div>

          {error && <div className="error-msg">{error}</div>}

          <button 
            type="submit" 
            disabled={loading}
            className="btn-login"
          >
            {loading ? 'Loading...' : 'Masuk'}
          </button>
        </form>
      </div>
    </div>
  );
}
```

---

### 2. 🏪 **Gudang (Inventory Management)**

**Fitur:**
- ✅ Cari barang by nama/kode + customer (optional)
- ✅ Tampilkan info cards: Last Unit Price, Last Unit Cost, Last Sale Qty, Last Order Date, New Unit Cost
- ✅ Foto produk (multiple upload)
- ✅ Tabel detail harga per supplier (expandable rows)
- ✅ Keyboard shortcuts (F1=Cari barang, F2=Cari customer, dll)
- ✅ CRUD produk + harga

**React Component:**
```jsx
// src/pages/GudangPage.jsx
import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';

export default function GudangPage() {
  const { profile } = useAuth();
  const [searchBarang, setSearchBarang] = useState('');
  const [searchCustomer, setSearchCustomer] = useState('');
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [infoCards, setInfoCards] = useState({
    lastUnitPrice: null,
    lastUnitCost: null,
    lastSaleQty: null,
    lastOrderDate: null,
    newUnitCost: null,
  });

  const [suppliers, setSuppliers] = useState([]);
  const [loading, setLoading] = useState(false);

  // Fetch last sale info when product selected
  useEffect(() => {
    if (selectedProduct) {
      fetchLastSaleInfo();
    }
  }, [selectedProduct]);

  async function fetchLastSaleInfo() {
    // Query sale_items untuk last sale data
    const { data } = await supabase
      .from('sale_items')
      .select('*, sales(*)')
      .eq('product_id', selectedProduct.id)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (data) {
      setInfoCards({
        lastUnitPrice: data.harga_jual,
        lastUnitCost: data.harga_beli,
        lastSaleQty: data.qty,
        lastOrderDate: data.sales.order_date,
        newUnitCost: null, // Calculate from product_prices
      });
    }
  }

  async function searchProducts() {
    setLoading(true);
    const { data } = await supabase
      .from('products')
      .select('*')
      .ilike('nama', `%${searchBarang}%`)
      .eq('aktif', true);
    setLoading(false);
    return data;
  }

  const canEdit = profile?.role === 'admin' || profile?.role === 'staff_gudang';

  return (
    <div className="gudang-page">
      <div className="page-header">
        <div>
          <h1>Gudang</h1>
          <p>Cek stok & harga barang</p>
        </div>
        {canEdit && (
          <button className="btn-primary" onClick={() => openAddModal()}>
            + Tambah Barang
          </button>
        )}
      </div>

      <div className="search-section">
        <div className="search-field">
          <label>Nama / Kode Barang</label>
          <input
            type="text"
            value={searchBarang}
            onChange={(e) => setSearchBarang(e.target.value)}
            placeholder="Ketik nama atau kode..."
          />
        </div>
        
        <div className="search-field">
          <label>Nama Customer <span className="optional">(opsional)</span></label>
          <input
            type="text"
            value={searchCustomer}
            onChange={(e) => setSearchCustomer(e.target.value)}
            placeholder="Ketik nama customer..."
          />
        </div>
      </div>

      {/* Info Cards */}
      <div className="info-cards">
        <InfoCard 
          icon="pi-tag" 
          label="Last Unit Price" 
          value={infoCards.lastUnitPrice} 
        />
        <InfoCard 
          icon="pi-dollar" 
          label="Last Unit Cost" 
          value={infoCards.lastUnitCost} 
        />
        <InfoCard 
          icon="pi-box" 
          label="Last Sale Qty" 
          value={infoCards.lastSaleQty} 
          unit=" pcs"
        />
        <InfoCard 
          icon="pi-calendar" 
          label="Last Order Date" 
          value={infoCards.lastOrderDate} 
          isDate 
        />
        <InfoCard 
          icon="pi-shopping-cart" 
          label="New Unit Cost" 
          value={infoCards.newUnitCost}
          accent 
        />
      </div>

      {/* Product Photos */}
      {selectedProduct?.foto_urls && (
        <div className="product-photos">
          <h3>Foto Produk</h3>
          <div className="photos-grid">
            {selectedProduct.foto_urls.map((url, idx) => (
              <img key={idx} src={url} alt={`Foto ${idx + 1}`} />
            ))}
          </div>
        </div>
      )}

      {/* Supplier Prices Table */}
      <div className="suppliers-table">
        {/* Table component here */}
      </div>
    </div>
  );
}

function InfoCard({ icon, label, value, unit = '', isDate = false, accent = false }) {
  const formatValue = () => {
    if (value === null) return '—';
    if (isDate) return new Date(value).toLocaleDateString('id-ID');
    if (typeof value === 'number') {
      return `Rp ${value.toLocaleString('id-ID')}${unit}`;
    }
    return `${value}${unit}`;
  };

  return (
    <div className={`info-card ${accent ? 'accent' : ''} ${value !== null ? 'filled' : ''}`}>
      <div className="ic-icon">
        <i className={`pi ${icon}`}></i>
      </div>
      <div className="ic-body">
        <span className="ic-label">{label}</span>
        <span className="ic-value">{formatValue()}</span>
      </div>
    </div>
  );
}
```

---

### 3. 💰 **Penjualan (Sales Management)**

**Flow:** Menu → Buat/Edit/List

#### **A. Menu Penjualan**
```jsx
// src/pages/penjualan/PenjualanMenuPage.jsx
import { Link } from 'react-router-dom';
import { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';

export default function PenjualanMenuPage() {
  const [stats, setStats] = useState({
    today: 0,
    week: 0,
    month: 0,
    total: 0,
  });

  useEffect(() => {
    loadStats();
  }, []);

  async function loadStats() {
    const today = new Date().toISOString().split('T')[0];
    
    // Count today's orders
    const { count: todayCount } = await supabase
      .from('sales')
      .select('*', { count: 'exact', head: true })
      .gte('order_date', today);
    
    // Total orders
    const { count: totalCount } = await supabase
      .from('sales')
      .select('*', { count: 'exact', head: true });

    setStats({
      today: todayCount || 0,
      week: 0, // Calculate
      month: 0, // Calculate
      total: totalCount || 0,
    });
  }

  return (
    <div className="penjualan-menu-page">
      <h1>Menu Penjualan</h1>
      <p>Pilih menu yang ingin diakses</p>

      <div className="menu-grid">
        <Link to="/penjualan/buat" className="menu-card">
          <i className="pi pi-plus-circle"></i>
          <h3>Tambah Penjualan</h3>
          <p>Buat order penjualan baru</p>
        </Link>

        <Link to="/penjualan/edit" className="menu-card">
          <i className="pi pi-pencil"></i>
          <h3>Edit Penjualan</h3>
          <p>Edit order penjualan yang sudah ada</p>
        </Link>

        <Link to="/penjualan/list" className="menu-card">
          <i className="pi pi-list"></i>
          <h3>Daftar Penjualan</h3>
          <p>Lihat daftar dan riwayat order</p>
        </Link>
      </div>

      <div className="stats-cards">
        <StatCard icon="pi-calendar" label="Hari Ini" value={`${stats.today} order`} />
        <StatCard icon="pi-calendar-plus" label="Minggu Ini" value={`${stats.week} order`} />
        <StatCard icon="pi-chart-bar" label="Bulan Ini" value={`${stats.month} order`} />
        <StatCard icon="pi-database" label="Total Order" value={`${stats.total} order`} />
      </div>
    </div>
  );
}
```

#### **B. Buat Order Penjualan**
```jsx
// src/pages/penjualan/PenjualanBuatPage.jsx
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';

export default function PenjualanBuatPage() {
  const navigate = useNavigate();
  const [form, setForm] = useState({
    order_date: formatDate(new Date()),
    customer_id: null,
    diantar: true,
    limit_bulan: 0,
    salesman: 'A',
  });

  const [selectedCustomer, setSelectedCustomer] = useState(null);
  const [showAddCustomer, setShowAddCustomer] = useState(false);

  async function submitOrder(e) {
    e.preventDefault();
    
    // Create draft sale
    const { data: sale, error } = await supabase
      .from('sales')
      .insert({
        order_date: form.order_date,
        customer_id: selectedCustomer.id,
        customer_nama: selectedCustomer.nama,
        customer_alamat: selectedCustomer.alamat,
        customer_telp: selectedCustomer.no_telp,
        diantar: form.diantar,
        limit_bulan: form.limit_bulan,
        salesman: form.salesman,
        subtotal: 0,
        status: 'draft',
      })
      .select()
      .single();

    if (!error) {
      // Save to sessionStorage and go to input page
      sessionStorage.setItem('penjualan_draft', JSON.stringify({
        sale_id: sale.id,
        ...form,
        customer: selectedCustomer,
      }));
      navigate('/penjualan/input');
    }
  }

  return (
    <div className="penjualan-page">
      <div className="form-card">
        <div className="form-header">
          <h1>Buat Order Penjualan</h1>
          <p>Step 1: Informasi Order & Customer</p>
        </div>

        <form onSubmit={submitOrder} className="order-form">
          <div className="form-col-left">
            {/* No Order (readonly) */}
            <div className="form-row">
              <label>No. Order</label>
              <input
                type="text"
                value="Auto generate saat save"
                readOnly
                disabled
              />
            </div>

            {/* Order Date */}
            <div className="form-row">
              <label className="required">Tanggal Order</label>
              <input
                type="text"
                value={form.order_date}
                onChange={(e) => setForm({ ...form, order_date: e.target.value })}
                placeholder="DD/MM/YY"
              />
            </div>

            {/* Customer Search */}
            <div className="form-row">
              <label className="required">Customer</label>
              {!showAddCustomer ? (
                <>
                  <input
                    type="text"
                    placeholder="Ketik nama customer & tekan Enter..."
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') openCustomerSearch();
                      if (e.key === 'F2') setShowAddCustomer(true);
                    }}
                  />
                  {selectedCustomer && (
                    <div className="customer-info">
                      <h4>{selectedCustomer.nama}</h4>
                      <p>{selectedCustomer.alamat}</p>
                      <p>Limit: Rp {selectedCustomer.limit_kredit.toLocaleString()}</p>
                    </div>
                  )}
                </>
              ) : (
                <AddCustomerForm
                  onSave={(customer) => {
                    setSelectedCustomer(customer);
                    setShowAddCustomer(false);
                  }}
                  onCancel={() => setShowAddCustomer(false)}
                />
              )}
            </div>
          </div>

          <div className="form-col-right">
            {/* Pengiriman */}
            <div className="form-row">
              <label>Pengiriman</label>
              <div className="radio-group">
                <RadioOption
                  label="Diantar"
                  icon="pi-truck"
                  active={form.diantar === true}
                  onClick={() => setForm({ ...form, diantar: true })}
                />
                <RadioOption
                  label="Diambil"
                  icon="pi-shopping-bag"
                  active={form.diantar === false}
                  onClick={() => setForm({ ...form, diantar: false })}
                />
              </div>
            </div>

            {/* Jatuh Tempo */}
            <div className="form-row">
              <label>Jatuh Tempo</label>
              <div className="radio-group">
                <RadioOption label="1 Bulan" active={form.limit_bulan === 0} onClick={() => setForm({ ...form, limit_bulan: 0 })} />
                <RadioOption label="2 Bulan" active={form.limit_bulan === 1} onClick={() => setForm({ ...form, limit_bulan: 1 })} />
                <RadioOption label="3 Bulan" active={form.limit_bulan === 2} onClick={() => setForm({ ...form, limit_bulan: 2 })} />
              </div>
            </div>

            {/* Salesman */}
            <div className="form-row">
              <label>Salesman</label>
              <div className="radio-group radio-group-wrap">
                {['A', 'B', 'C', 'D', 'E'].map((s) => (
                  <RadioOption
                    key={s}
                    label={`Sales ${s}`}
                    active={form.salesman === s}
                    onClick={() => setForm({ ...form, salesman: s })}
                  />
                ))}
              </div>
            </div>
          </div>

          <div className="form-actions">
            <button type="button" className="btn-secondary" onClick={() => navigate('/penjualan')}>
              Batal
            </button>
            <button type="submit" className="btn-primary" disabled={!selectedCustomer}>
              Lanjut ke Input Barang
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function RadioOption({ label, icon, active, onClick }) {
  return (
    <label className={`radio-option ${active ? 'active' : ''}`} onClick={onClick}>
      <input type="radio" checked={active} onChange={() => {}} />
      <span className="radio-label">
        {icon && <i className={`pi ${icon}`}></i>}
        {label}
      </span>
    </label>
  );
}

function AddCustomerForm({ onSave, onCancel }) {
  const [form, setForm] = useState({
    nama: '',
    alamat: '',
    no_telp: '',
    limit_kredit: 10000000,
  });

  async function handleSubmit(e) {
    e.preventDefault();
    
    // Generate kode customer
    const { data: existing } = await supabase
      .from('customers')
      .select('kode')
      .order('kode', { ascending: false })
      .limit(1)
      .single();

    const lastNum = existing ? parseInt(existing.kode.substring(1)) : 0;
    const newKode = `C${String(lastNum + 1).padStart(3, '0')}`;

    // Insert customer
    const { data: newCustomer, error } = await supabase
      .from('customers')
      .insert({
        kode: newKode,
        nama: form.nama,
        alamat: form.alamat || null,
        no_telp: form.no_telp || null,
        limit_kredit: form.limit_kredit,
        saldo_piutang: 0,
        aktif: true,
      })
      .select()
      .single();

    if (!error) {
      onSave(newCustomer);
    }
  }

  return (
    <div className="inline-add-customer">
      <div className="iac-header">
        <i className="pi pi-user-plus"></i>
        <span>Tambah Customer Baru</span>
        <button className="iac-close" onClick={onCancel}>
          <i className="pi pi-times"></i>
        </button>
      </div>
      <form onSubmit={handleSubmit} className="iac-grid">
        <div className="iac-field iac-full">
          <label>Nama Customer *</label>
          <input
            type="text"
            value={form.nama}
            onChange={(e) => setForm({ ...form, nama: e.target.value })}
            required
          />
        </div>
        <div className="iac-field">
          <label>Alamat (opsional)</label>
          <input
            type="text"
            value={form.alamat}
            onChange={(e) => setForm({ ...form, alamat: e.target.value })}
          />
        </div>
        <div className="iac-field">
          <label>No. Telp (opsional)</label>
          <input
            type="text"
            value={form.no_telp}
            onChange={(e) => setForm({ ...form, no_telp: e.target.value })}
          />
        </div>
        <div className="iac-field">
          <label>Limit Kredit (opsional)</label>
          <input
            type="number"
            value={form.limit_kredit}
            onChange={(e) => setForm({ ...form, limit_kredit: parseInt(e.target.value) })}
          />
        </div>
        <div className="iac-actions">
          <button type="button" className="btn-secondary" onClick={onCancel}>
            Batal
          </button>
          <button type="submit" className="btn-primary">
            Simpan
          </button>
        </div>
      </form>
    </div>
  );
}

function formatDate(date) {
  const d = new Date(date);
  const day = String(d.getDate()).padStart(2, '0');
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const year = String(d.getFullYear()).slice(-2);
  return `${day}/${month}/${year}`;
}
```

---

### 4. 📊 **Master Data (Customer & Supplier)**

```jsx
// src/pages/master-data/MasterDataPage.jsx
import { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';

export default function MasterDataPage() {
  const { profile } = useAuth();
  const [activeTab, setActiveTab] = useState('customer');
  const [customerRows, setCustomerRows] = useState([]);
  const [supplierRows, setSupplierRows] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(false);

  const canEdit = profile?.role === 'admin' || profile?.role === 'staff_gudang';

  useEffect(() => {
    if (activeTab === 'customer') {
      loadCustomers();
    } else {
      loadSuppliers();
    }
  }, [activeTab]);

  async function loadCustomers() {
    setLoading(true);
    const { data } = await supabase
      .from('customers')
      .select('*')
      .eq('aktif', true)
      .order('nama');
    setCustomerRows(data || []);
    setLoading(false);
  }

  async function loadSuppliers() {
    setLoading(true);
    const { data } = await supabase
      .from('suppliers')
      .select('*')
      .eq('aktif', true)
      .order('nama');
    setSupplierRows(data || []);
    setLoading(false);
  }

  const filteredRows = activeTab === 'customer'
    ? customerRows.filter(c => 
        c.nama.toLowerCase().includes(searchQuery.toLowerCase()) ||
        c.kode.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : supplierRows.filter(s => 
        s.nama.toLowerCase().includes(searchQuery.toLowerCase()) ||
        s.kode.toLowerCase().includes(searchQuery.toLowerCase())
      );

  return (
    <div className="master-data-page">
      <div className="page-header">
        <div>
          <h1>Data Master</h1>
          <p>Kelola data customer dan supplier</p>
        </div>
        {canEdit && (
          <button className="btn-primary" onClick={() => openAddModal()}>
            + Tambah {activeTab === 'customer' ? 'Customer' : 'Supplier'}
          </button>
        )}
      </div>

      <div className="tab-nav">
        <button
          className={`tab-btn ${activeTab === 'customer' ? 'active' : ''}`}
          onClick={() => setActiveTab('customer')}
        >
          <i className="pi pi-users"></i>
          <span>Customer</span>
          <span className="tab-count">{customerRows.length}</span>
        </button>
        <button
          className={`tab-btn ${activeTab === 'supplier' ? 'active' : ''}`}
          onClick={() => setActiveTab('supplier')}
        >
          <i className="pi pi-truck"></i>
          <span>Supplier</span>
          <span className="tab-count">{supplierRows.length}</span>
        </button>
      </div>

      <div className="search-bar">
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder={`Cari ${activeTab === 'customer' ? 'customer' : 'supplier'}...`}
        />
      </div>

      {activeTab === 'customer' ? (
        <CustomerTable rows={filteredRows} loading={loading} canEdit={canEdit} />
      ) : (
        <SupplierTable rows={filteredRows} loading={loading} canEdit={canEdit} />
      )}
    </div>
  );
}

function CustomerTable({ rows, loading, canEdit }) {
  if (loading) return <div className="loading">Loading...</div>;
  if (rows.length === 0) return <div className="empty">Tidak ada data</div>;

  return (
    <table className="data-table">
      <thead>
        <tr>
          <th>#</th>
          <th>Kode</th>
          <th>Nama Customer</th>
          <th>Alamat</th>
          <th>No. Telp</th>
          <th>Limit Kredit</th>
          <th>Saldo Piutang</th>
          {canEdit && <th>Aksi</th>}
        </tr>
      </thead>
      <tbody>
        {rows.map((row, i) => (
          <tr key={row.id}>
            <td>{i + 1}</td>
            <td><span className="kode-badge">{row.kode}</span></td>
            <td>{row.nama}</td>
            <td>{row.alamat || '—'}</td>
            <td>{row.no_telp || '—'}</td>
            <td>Rp {row.limit_kredit.toLocaleString('id-ID')}</td>
            <td>Rp {row.saldo_piutang.toLocaleString('id-ID')}</td>
            {canEdit && (
              <td>
                <button onClick={() => editCustomer(row)}>
                  <i className="pi pi-pencil"></i>
                </button>
                <button onClick={() => deleteCustomer(row)}>
                  <i className="pi pi-trash"></i>
                </button>
              </td>
            )}
          </tr>
        ))}
      </tbody>
    </table>
  );
}

function SupplierTable({ rows, loading, canEdit }) {
  // Similar to CustomerTable
  return <div>Supplier Table...</div>;
}
```

---

## 🔄 Tech Stack Conversion

### **Before (Vue):**
```
- Vue 3 (Composition API)
- Vue Router
- Pinia (State Management)
- Vite
- Supabase Client
```

### **After (React):**
```
- React 18
- React Router v6
- Context API / Zustand (State Management)
- Vite (same)
- Supabase Client (same)
```

---

## 📦 Dependencies untuk React

```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "@supabase/supabase-js": "^2.38.0",
    "zustand": "^4.4.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.0",
    "vite": "^5.0.0"
  }
}
```

---

## 🛠️ Rencana Konversi (Step by Step)

### **Phase 1: Setup Project** (2-3 jam)
1. ✅ Create new React + Vite project
2. ✅ Setup folder structure
3. ✅ Install dependencies
4. ✅ Configure Supabase client
5. ✅ Setup React Router
6. ✅ Create AuthContext

### **Phase 2: Core Pages** (1 hari)
1. ✅ LoginPage
2. ✅ DashboardPage
3. ✅ MainLayout (with sidebar & navbar)
4. ✅ Protected Routes

### **Phase 3: Master Data** (4-5 jam)
1. ✅ MasterDataPage (Customer & Supplier tabs)
2. ✅ CRUD modals
3. ✅ Table components with search & pagination

### **Phase 4: Gudang** (6-8 jam)
1. ✅ GudangPage (search + info cards)
2. ✅ Product CRUD
3. ✅ Supplier prices table
4. ✅ Photo upload component

### **Phase 5: Penjualan** (1 hari)
1. ✅ PenjualanMenuPage
2. ✅ PenjualanBuatPage (Step 1: Form)
3. ✅ PenjualanInputPage (Step 2: Items)
4. ✅ PenjualanListPage
5. ✅ PenjualanEditPage

### **Phase 6: Advanced Features** (4-6 jam)
1. ✅ Pembelian (similar to Penjualan)
2. ✅ Penagihan
3. ✅ Laporan

### **Phase 7: Polish & Testing** (3-4 jam)
1. ✅ CSS migration
2. ✅ Keyboard shortcuts
3. ✅ Error handling
4. ✅ Loading states
5. ✅ Testing

---

## 📝 Catatan Penting

### **Perbedaan Vue vs React:**

| Feature | Vue 3 | React 18 |
|---------|-------|----------|
| State | `ref()`, `reactive()` | `useState()` |
| Side Effects | `watch()`, `watchEffect()` | `useEffect()` |
| Computed | `computed()` | `useMemo()` |
| Two-way Binding | `v-model` | `value + onChange` |
| Conditional | `v-if`, `v-show` | `{condition && <Component />}` |
| Loop | `v-for` | `{array.map()}` |
| Event | `@click` | `onClick` |
| Class Binding | `:class="{ active: true }"` | `className={active ? 'active' : ''}` |

### **Supabase RLS tetap sama:**
- Tidak perlu ubah database
- Tidak perlu ubah RLS policies
- Cukup ganti frontend framework

---

## 🚀 Quick Start

Mau saya mulai konversi dari mana?

**Pilihan:**
1. **Full Conversion** - Saya convert semua sekaligus (2-3 hari)
2. **Proof of Concept** - Saya convert Login + Dashboard dulu (2-3 jam)
3. **Per Module** - Pilih modul mana yang mau diconvert dulu

**Ketik pilihan Anda (1/2/3):**
