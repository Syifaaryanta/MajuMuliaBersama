-- ============================================================
-- 12. MASTER DATA TERMS + AUTO SALDO PIUTANG
-- ============================================================

-- 1) Tambah kolom jatuh tempo untuk customer dan supplier
ALTER TABLE customers
  ADD COLUMN IF NOT EXISTS jatuh_tempo_bulan INTEGER;

UPDATE customers
SET jatuh_tempo_bulan = 1
WHERE jatuh_tempo_bulan IS NULL OR jatuh_tempo_bulan NOT IN (1, 2, 3);

ALTER TABLE customers
  ALTER COLUMN jatuh_tempo_bulan SET DEFAULT 1,
  ALTER COLUMN jatuh_tempo_bulan SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'customers_jatuh_tempo_bulan_check'
  ) THEN
    ALTER TABLE customers
      ADD CONSTRAINT customers_jatuh_tempo_bulan_check
      CHECK (jatuh_tempo_bulan IN (1, 2, 3));
  END IF;
END $$;

ALTER TABLE suppliers
  ADD COLUMN IF NOT EXISTS jatuh_tempo_bulan INTEGER;

UPDATE suppliers
SET jatuh_tempo_bulan = 1
WHERE jatuh_tempo_bulan IS NULL OR jatuh_tempo_bulan NOT IN (1, 2, 3);

ALTER TABLE suppliers
  ALTER COLUMN jatuh_tempo_bulan SET DEFAULT 1,
  ALTER COLUMN jatuh_tempo_bulan SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'suppliers_jatuh_tempo_bulan_check'
  ) THEN
    ALTER TABLE suppliers
      ADD CONSTRAINT suppliers_jatuh_tempo_bulan_check
      CHECK (jatuh_tempo_bulan IN (1, 2, 3));
  END IF;
END $$;

-- 2) Auto sinkron saldo piutang customer berdasar perubahan sales
CREATE OR REPLACE FUNCTION sync_customer_saldo_piutang_from_sales()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  old_total NUMERIC(15,2);
  new_total NUMERIC(15,2);
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status = 'completed' AND NEW.customer_id IS NOT NULL THEN
      new_total := COALESCE(NEW.subtotal, 0) + COALESCE(NEW.extra_charge_amount, 0);
      UPDATE customers
      SET saldo_piutang = COALESCE(saldo_piutang, 0) + new_total
      WHERE id = NEW.customer_id;
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    old_total := COALESCE(OLD.subtotal, 0) + COALESCE(OLD.extra_charge_amount, 0);
    new_total := COALESCE(NEW.subtotal, 0) + COALESCE(NEW.extra_charge_amount, 0);

    IF OLD.status = 'completed' AND OLD.customer_id IS NOT NULL THEN
      UPDATE customers
      SET saldo_piutang = GREATEST(0, COALESCE(saldo_piutang, 0) - old_total)
      WHERE id = OLD.customer_id;
    END IF;

    IF NEW.status = 'completed' AND NEW.customer_id IS NOT NULL THEN
      UPDATE customers
      SET saldo_piutang = COALESCE(saldo_piutang, 0) + new_total
      WHERE id = NEW.customer_id;
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    IF OLD.status = 'completed' AND OLD.customer_id IS NOT NULL THEN
      old_total := COALESCE(OLD.subtotal, 0) + COALESCE(OLD.extra_charge_amount, 0);
      UPDATE customers
      SET saldo_piutang = GREATEST(0, COALESCE(saldo_piutang, 0) - old_total)
      WHERE id = OLD.customer_id;
    END IF;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_customer_saldo_piutang_on_sales ON sales;

CREATE TRIGGER trg_sync_customer_saldo_piutang_on_sales
AFTER INSERT OR UPDATE OR DELETE ON sales
FOR EACH ROW
EXECUTE FUNCTION sync_customer_saldo_piutang_from_sales();
