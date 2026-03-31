-- ============================================================
-- 11_drop_salesman_column.sql
-- Hapus kolom salesman dari tabel sales karena tidak dipakai lagi
-- ============================================================

-- Drop view dulu karena sebelumnya bergantung ke kolom salesman.
DROP VIEW IF EXISTS v_sales_summary;

ALTER TABLE sales
  DROP COLUMN IF EXISTS salesman;

CREATE VIEW v_sales_summary AS
SELECT
  s.id,
  s.no_order,
  s.no_faktur,
  s.extra_charge_desc,
  s.extra_charge_amount,
  s.sender_note,
  s.order_date,
  s.customer_nama,
  s.customer_alamat,
  s.diantar,
  s.limit_bulan,
  s.subtotal,
  s.status,
  COUNT(si.id) as total_items,
  SUM(si.qty) as total_qty,
  s.created_at
FROM sales s
LEFT JOIN sale_items si ON s.id = si.sale_id
GROUP BY s.id;
