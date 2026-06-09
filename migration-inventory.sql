-- ═══════════════════════════════════════════════════════════
--  تحديث: إضافة جداول الفروع والمخزون
--  انسخ هذا كاملاً والصقه في Supabase ← SQL Editor ← Run
-- ═══════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────
-- 1) جدول الفروع (ديناميكي)
-- ─────────────────────────────────────────────
create table if not exists public.branches (
  id          bigint generated always as identity primary key,
  code        text unique not null,          -- معرّف قصير: yider, tripoli, lab
  name        text not null,                 -- الاسم المعروض: فرع يدر
  created_at  timestamptz default now()
);

-- إدخال الفروع الحالية (مرة واحدة)
insert into public.branches (code, name) values
  ('all',     'جميع الفروع'),
  ('yider',   'فرع يدر'),
  ('tripoli', 'فرع طرابلس'),
  ('lab',     'المختبر')
on conflict (code) do nothing;

-- ─────────────────────────────────────────────
-- 2) جدول المخزون (الأصناف حسب الفرع)
-- ─────────────────────────────────────────────
create table if not exists public.inventory (
  id          bigint generated always as identity primary key,
  item_name   text not null,                 -- اسم الصنف
  category    text,                          -- التصنيف (مطاعم/طبي/...)
  branch      text default 'all',            -- الفرع (code)
  qty         numeric default 0,             -- الكمية الحالية
  unit        text default 'قطعة',           -- الوحدة
  min_qty     numeric default 0,             -- الحد الأدنى (للتنبيه)
  unit_cost   numeric default 0,             -- تكلفة الوحدة
  supplier_id bigint references public.suppliers(id) on delete set null,
  notes       text,
  updated_at  timestamptz default now(),
  created_at  timestamptz default now()
);

-- ─────────────────────────────────────────────
-- 3) تفعيل الأمان (RLS) للجدولين الجديدين
-- ─────────────────────────────────────────────
alter table public.branches  enable row level security;
alter table public.inventory enable row level security;

-- branches: الكل يقرأ، المخوّلون يعدّلون
drop policy if exists "auth read branches" on public.branches;
create policy "auth read branches" on public.branches
  for select using (auth.role() = 'authenticated');
drop policy if exists "editors write branches" on public.branches;
create policy "editors write branches" on public.branches
  for all using (public.can_edit()) with check (public.can_edit());

-- inventory: الكل يقرأ، المخوّلون يعدّلون
drop policy if exists "auth read inventory" on public.inventory;
create policy "auth read inventory" on public.inventory
  for select using (auth.role() = 'authenticated');
drop policy if exists "editors write inventory" on public.inventory;
create policy "editors write inventory" on public.inventory
  for all using (public.can_edit()) with check (public.can_edit());

-- ═══════════════════════════════════════════════════════════
--  انتهى. اضغط RUN.
-- ═══════════════════════════════════════════════════════════
