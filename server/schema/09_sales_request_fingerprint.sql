-- Add idempotency fingerprint for sales draft creation
-- This prevents duplicate draft rows when multiple admins submit the same payload nearly at the same time.

alter table public.sales
add column if not exists request_fingerprint text;

create unique index if not exists sales_request_fingerprint_unique_idx
on public.sales (request_fingerprint)
where request_fingerprint is not null;
