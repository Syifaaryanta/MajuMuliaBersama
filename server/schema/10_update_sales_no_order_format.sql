-- Pisahkan nomor order (internal) dan nomor fraktur (nota)
-- Aturan:
-- 1) no_order: format YYNNN, isi celah jika ada data dihapus (mis. 26001 bisa dipakai lagi)
-- 2) no_faktur: format YYNNN, naik terus dan tidak isi celah (untuk nota/print)

CREATE OR REPLACE FUNCTION generate_no_order()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_tahun TEXT;
  v_new_no_int INTEGER;
  v_new_no TEXT;
BEGIN
  v_tahun := TO_CHAR(CURRENT_DATE, 'YY');

  SELECT s.n INTO v_new_no_int
  FROM generate_series(1, 999) AS s(n)
  WHERE NOT EXISTS (
    SELECT 1
    FROM sales
    WHERE no_order = v_tahun || LPAD(s.n::TEXT, 3, '0')
  )
  ORDER BY s.n
  LIMIT 1;

  IF v_new_no_int IS NULL THEN
    v_new_no_int := 1;
  END IF;

  v_new_no := v_tahun || LPAD(v_new_no_int::TEXT, 3, '0');
  RETURN v_new_no;
END;
$$;

ALTER TABLE public.sales
ADD COLUMN IF NOT EXISTS no_faktur TEXT;

ALTER TABLE public.sales
ADD COLUMN IF NOT EXISTS extra_charge_desc TEXT;

ALTER TABLE public.sales
ADD COLUMN IF NOT EXISTS extra_charge_amount NUMERIC(15,2) NOT NULL DEFAULT 0;

ALTER TABLE public.sales
ADD COLUMN IF NOT EXISTS sender_note TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS sales_no_faktur_unique_idx
ON public.sales (no_faktur)
WHERE no_faktur IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.sales_faktur_counter (
  tahun TEXT PRIMARY KEY,
  last_no INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION generate_no_faktur()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  v_tahun TEXT;
  v_next_no INTEGER;
BEGIN
  v_tahun := TO_CHAR(CURRENT_DATE, 'YY');

  INSERT INTO public.sales_faktur_counter (tahun, last_no)
  VALUES (v_tahun, 1)
  ON CONFLICT (tahun)
  DO UPDATE SET
    last_no = sales_faktur_counter.last_no + 1,
    updated_at = NOW()
  RETURNING last_no INTO v_next_no;

  RETURN v_tahun || LPAD(v_next_no::TEXT, 3, '0');
END;
$$;

CREATE OR REPLACE FUNCTION auto_generate_no_faktur_on_complete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = 'completed' AND (NEW.no_faktur IS NULL OR NEW.no_faktur = '') THEN
    NEW.no_faktur := generate_no_faktur();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_no_faktur_on_complete ON public.sales;
CREATE TRIGGER trg_auto_no_faktur_on_complete
  BEFORE INSERT OR UPDATE ON public.sales
  FOR EACH ROW
  EXECUTE FUNCTION auto_generate_no_faktur_on_complete();

COMMENT ON FUNCTION generate_no_order() IS 'Generate nomor order internal format YYNNN (isi celah / gap)';
COMMENT ON FUNCTION generate_no_faktur() IS 'Generate nomor fraktur nota format YYNNN (naik terus, tidak isi gap)';
