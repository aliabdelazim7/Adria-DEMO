-- =============================================================================
-- ADRIA — إعداد قاعدة البيانات الشاملة لبوتيك الأزياء والملابس (Demo System)
-- انسخ محتوى هذا الملف بالكامل والصقه في:
-- Supabase Dashboard > SQL Editor > New query > Run
-- =============================================================================

-- ---------- (1) الإضافات (Extensions) ----------
create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

-- ---------- (2) إنشاء الجداول ----------

-- إعدادات المتجر
create table if not exists store_settings (
  id uuid default gen_random_uuid() primary key,
  name text not null default 'ADRIA - بوتيك الملابس والأزياء',
  currency text default 'ج.م',
  logo text default 'https://cdn-icons-png.flaticon.com/512/3143/3143641.png',
  tax_rate numeric default 0,
  theme_color text default '#4f46e5',
  address text default 'القاهرة - المعادي - شارع النصر',
  phone text default '01000000000',
  phone2 text default '01100000000',
  whatsapp_country_code text default '2',
  initial_balance numeric default 15000,
  location_url text default '',
  allow_cashier_employee_advance boolean default true,
  day_start_hour integer default 3,
  receipt_header text default 'أهلاً بكم في بوتيك أدريا للأزياء والملابس',
  receipt_footer text default 'شكراً لزيارتكم أدريا نتمنى لكم تجربة تسوق رائعة'
);

-- الفئات
create table if not exists categories (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  created_at timestamptz default now()
);

-- المنتجات
create table if not exists products (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  barcode text unique,
  code text,
  purchase_price numeric default 0,
  average_purchase_price numeric default 0,
  sale_price numeric default 0,
  discount_price numeric default 0,
  wholesale_price numeric default 0,
  half_wholesale_price numeric default 0,
  stock_quantity integer default 0,
  display_quantity integer default 0,
  factory_quantity integer default 0,
  unit text default 'قطعة',
  category_id uuid references categories(id) on delete set null,
  is_hidden boolean default false,
  color text,
  supplier_name text,
  created_at timestamptz default now()
);

-- العملاء
create table if not exists customers (
  id uuid default gen_random_uuid() primary key,
  custom_id text unique,
  name text not null default 'بدون اسم',
  phone text unique not null,
  card_number text,
  address text,
  created_at timestamptz default now()
);

-- الموردين
create table if not exists suppliers (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  phone text,
  address text,
  created_at timestamptz default now()
);

-- سيارات الصيانة والاشتراكات
create table if not exists car_subscriptions (
  id uuid primary key default gen_random_uuid(),
  car_number text not null,
  car_details text,
  customer_name text,
  customer_phone text,
  status text default 'active',
  subscription_duration_months integer,
  subscription_frequency_days integer,
  created_at timestamptz default now()
);

create table if not exists maintenance_appointments (
  id uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references car_subscriptions(id) on delete cascade,
  appointment_date date not null,
  description text,
  report text,
  cost numeric default 0,
  status text default 'pending',
  is_reminded boolean default false,
  created_at timestamptz default now()
);

-- فواتير المشتريات
create table if not exists purchase_invoices (
  id uuid default gen_random_uuid() primary key,
  invoice_number text not null,
  supplier_id uuid references suppliers(id) on delete set null,
  total numeric not null default 0,
  paid_amount numeric default 0,
  paid_cash numeric default 0,
  paid_visa numeric default 0,
  paid_wallet numeric default 0,
  paid_instapay numeric default 0,
  payment_method text default 'cash',
  notes text,
  created_at timestamptz default now()
);

create table if not exists purchase_items (
  id uuid default gen_random_uuid() primary key,
  invoice_id uuid references purchase_invoices(id) on delete cascade,
  product_id uuid references products(id) on delete set null,
  quantity integer not null default 1,
  purchase_price numeric not null default 0
);

-- الفواتير (المبيعات)
create table if not exists orders (
  id text primary key,
  total numeric not null default 0,
  paid_amount numeric default 0,
  paid_cash numeric default 0,
  paid_visa numeric default 0,
  paid_wallet numeric default 0,
  paid_instapay numeric default 0,
  payment_method text default 'cash',
  type text default 'sale',
  customer_id uuid references customers(id) on delete set null,
  cashier_name text,
  car_id uuid references car_subscriptions(id) on delete set null,
  coupon_code text,
  discount_amount numeric default 0,
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  deletion_reason text,
  notes text,
  created_at timestamptz default now()
);
create index if not exists idx_orders_is_deleted on orders(is_deleted);
create index if not exists idx_orders_deleted_at on orders(deleted_at);

-- عداد الفواتير
create table if not exists invoice_counter (
  id int primary key default 1,
  current_value integer default 1,
  check (id = 1)
);

-- بنود الفاتورة
create table if not exists order_items (
  id uuid default gen_random_uuid() primary key,
  order_id text references orders(id) on delete cascade,
  product_id uuid references products(id) on delete set null,
  product_name text not null,
  barcode text,
  quantity integer default 1,
  returned_quantity integer default 0,
  refunded_amount numeric default 0,
  sale_price numeric default 0,
  purchase_price numeric default 0
);

-- المصروفات
create table if not exists expenses (
  id uuid default gen_random_uuid() primary key,
  category text not null,
  amount numeric not null default 0,
  note text,
  payment_method text default 'cash',
  paid_cash numeric default 0,
  paid_visa numeric default 0,
  paid_wallet numeric default 0,
  paid_instapay numeric default 0,
  car_id uuid references car_subscriptions(id) on delete set null,
  created_at timestamptz default now()
);

-- التمويل والسلف
create table if not exists financing_accounts (
  id uuid default gen_random_uuid() primary key,
  type text not null default 'loan',
  lender_name text not null,
  lender_phone text default '',
  lender_details text default '',
  description text default '',
  principal_amount numeric not null default 0,
  collection_amount numeric not null default 0,
  collection_date date not null,
  installment_count integer not null default 1,
  status text not null default 'open',
  created_at timestamptz default now()
);

create table if not exists financing_payments (
  id uuid default gen_random_uuid() primary key,
  account_id uuid references financing_accounts(id) on delete cascade,
  payment_type text not null,
  due_date date not null,
  amount numeric not null default 0,
  paid_amount numeric not null default 0,
  remaining_amount numeric not null default 0,
  status text not null default 'pending',
  paid_at timestamptz,
  expense_id uuid references expenses(id) on delete set null,
  note text,
  created_at timestamptz default now()
);

create table if not exists financing_transactions (
  id uuid default gen_random_uuid() primary key,
  account_id uuid references financing_accounts(id) on delete cascade,
  payment_id uuid references financing_payments(id) on delete cascade,
  transaction_type text not null,
  amount numeric not null default 0,
  remaining_after numeric not null default 0,
  payment_method text not null default 'cash',
  expense_id uuid references expenses(id) on delete set null,
  note text,
  created_at timestamptz default now()
);

-- المحاسبين / الكاشيرية
create table if not exists cashiers (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  password text,
  phone text,
  photo_url text,
  email text,
  full_access boolean default false,
  created_at timestamptz default now()
);

-- مستخدمو لوحة التحكم
create table if not exists admin_users (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  password text,
  email text,
  permissions jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);

-- الموظفين والرواتب
create table if not exists employees (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  job_title text,
  phone text,
  working_hours text,
  monthly_salary numeric default 0,
  annual_leave_balance numeric not null default 0,
  hire_date date default current_date,
  is_active boolean not null default true,
  cashier_id uuid references cashiers(id) on delete set null,
  created_at timestamptz default now()
);

create table if not exists employee_transactions (
  id uuid default gen_random_uuid() primary key,
  employee_id uuid references employees(id) on delete cascade,
  amount numeric not null,
  type text check (type in ('salary', 'advance', 'incentive')),
  payment_method text default 'cash',
  paid_cash numeric default 0,
  paid_visa numeric default 0,
  paid_wallet numeric default 0,
  paid_instapay numeric default 0,
  deductions numeric default 0,
  month text,
  note text,
  created_at timestamptz default now()
);

create table if not exists employee_leaves (
  id uuid default gen_random_uuid() primary key,
  employee_id uuid references employees(id) on delete cascade,
  start_date date not null,
  end_date date not null,
  days_count numeric not null default 1,
  leave_type text not null check (leave_type in ('paid', 'unpaid')),
  deduction_amount numeric not null default 0,
  month text,
  note text,
  created_at timestamptz default now()
);

create table if not exists employee_deductions (
  id uuid default gen_random_uuid() primary key,
  employee_id uuid references employees(id) on delete cascade,
  amount numeric not null,
  reason text,
  date date default current_date,
  month text,
  created_at timestamptz default now()
);

create table if not exists employee_bonuses (
  id uuid default gen_random_uuid() primary key,
  employee_id uuid references employees(id) on delete cascade,
  amount numeric not null,
  reason text,
  date date default current_date,
  month text,
  created_at timestamptz default now()
);

create table if not exists employee_attendance (
  id uuid default gen_random_uuid() primary key,
  employee_id uuid references employees(id) on delete cascade,
  check_in timestamptz not null default now(),
  check_out timestamptz,
  date date default current_date,
  notes text,
  created_at timestamptz default now()
);

-- اقتراحات المنتجات وملاحظات الكاشير والكوبونات
create table if not exists product_suggestions (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  notes text,
  is_purchased boolean default false,
  created_at timestamptz default now()
);

create table if not exists cashier_notes (
  id uuid default gen_random_uuid() primary key,
  cashier_name text not null,
  note text not null,
  is_read boolean default false,
  created_at timestamptz default now()
);

create table if not exists coupons (
  id uuid default gen_random_uuid() primary key,
  code text not null unique,
  discount_type text not null default 'percentage' check (discount_type in ('percentage','fixed')),
  discount_value numeric not null default 0,
  start_date timestamptz,
  end_date timestamptz,
  max_uses_per_customer integer,
  max_uses_total integer,
  used_count integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz default now()
);

create table if not exists wholesale_otp (
  id uuid default gen_random_uuid() primary key,
  code text not null,
  created_at timestamptz default now()
);

create table if not exists salespersons (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  created_at timestamptz default now()
);

create table if not exists partners (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  share_percentage numeric default 0,
  created_at timestamptz default now()
);

create table if not exists partner_transactions (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid references partners(id) on delete cascade,
  amount numeric not null,
  type text check (type in ('deposit', 'withdrawal')),
  note text,
  created_at timestamptz default now()
);

create table if not exists savings_vaults (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  balance numeric default 0,
  created_at timestamptz default now()
);

create table if not exists savings_transactions (
  id uuid default gen_random_uuid() primary key,
  vault_id uuid references savings_vaults(id) on delete cascade,
  amount numeric not null,
  type text check (type in ('deposit', 'withdrawal')),
  note text,
  created_at timestamptz default now()
);

create table if not exists devo_items (
  id uuid default gen_random_uuid() primary key,
  product_id uuid references products(id) on delete cascade,
  quantity integer not null default 1,
  reason text,
  created_at timestamptz default now()
);

create table if not exists write_offs (
  id uuid default gen_random_uuid() primary key,
  product_id uuid references products(id) on delete cascade,
  quantity integer not null default 1,
  reason text,
  created_at timestamptz default now()
);

create table if not exists stock_intakes (
  id uuid default gen_random_uuid() primary key,
  product_id uuid references products(id) on delete cascade,
  product_name text not null,
  quantity integer not null default 1,
  unit_cost numeric default 0,
  total_value numeric default 0,
  source text,
  note text,
  created_at timestamptz default now()
);

create table if not exists held_invoices (
  id uuid default gen_random_uuid() primary key,
  client_name text,
  client_phone text,
  cart jsonb not null default '[]'::jsonb,
  total numeric not null default 0,
  kind text default 'held',
  status text default 'pending',
  address text,
  created_at timestamptz default now()
);

create table if not exists materials (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  unit text default 'كيلو',
  cost_per_unit numeric default 0,
  stock_quantity numeric default 0,
  created_at timestamptz default now()
);

create table if not exists production_orders (
  id uuid default gen_random_uuid() primary key,
  product_id uuid references products(id) on delete set null,
  quantity integer not null default 1,
  status text default 'completed',
  created_at timestamptz default now()
);

create table if not exists production_materials (
  id uuid default gen_random_uuid() primary key,
  production_order_id uuid references production_orders(id) on delete cascade,
  material_id uuid references materials(id) on delete set null,
  quantity_used numeric not null default 0,
  unit_cost numeric default 0
);

-- ---------- (3) تفعيل RLS وسياسات الوصول ----------
do $$
declare t text;
begin
  foreach t in array array[
    'store_settings','categories','products','customers','suppliers',
    'car_subscriptions','maintenance_appointments','purchase_invoices','purchase_items',
    'orders','invoice_counter','order_items','expenses',
    'financing_accounts','financing_payments','financing_transactions',
    'cashiers','admin_users','employees','employee_transactions','employee_leaves',
    'employee_deductions','employee_bonuses','employee_attendance',
    'product_suggestions','cashier_notes','coupons','wholesale_otp',
    'salespersons','partners','partner_transactions','savings_vaults',
    'savings_transactions','devo_items','write_offs','stock_intakes',
    'held_invoices','materials','production_orders','production_materials'
  ]
  loop
    execute format('alter table %I enable row level security;', t);
    if not exists (
      select 1 from pg_policies where schemaname = 'public' and tablename = t and policyname = 'allow all'
    ) then
      execute format('create policy "allow all" on %I for all using (true) with check (true);', t);
    end if;
  end loop;
end $$;

-- ---------- (4) دالّات الـ RPC لشاشات الدخول ----------

create or replace function public.get_pos_login_data()
returns jsonb language sql security definer set search_path = public as $$
  select jsonb_build_object(
    'settings', (
      select jsonb_build_object(
        'name', s.name, 'currency', s.currency,
        'logo', s.logo, 'theme_color', s.theme_color
      ) from store_settings s limit 1
    ),
    'cashiers', (
      select coalesce(
        jsonb_agg(jsonb_build_object('id', c.id, 'name', c.name, 'email', c.email) order by c.created_at desc),
        '[]'::jsonb
      ) from cashiers c
    )
  );
$$;

create or replace function public.get_admin_login_data()
returns jsonb language sql security definer set search_path = public as $$
  select coalesce(
    jsonb_agg(jsonb_build_object('id', id, 'name', name, 'email', email, 'permissions', permissions) order by name),
    '[]'::jsonb
  ) from admin_users;
$$;

revoke all on function public.get_pos_login_data() from public;
grant execute on function public.get_pos_login_data() to anon, authenticated;

revoke all on function public.get_admin_login_data() from public;
grant execute on function public.get_admin_login_data() to anon, authenticated;

-- ---------- (5) تصفير الجداول وتغذية بيانات الديمو لبوتيك الملابس ----------

truncate table order_items cascade;
truncate table orders cascade;
truncate table purchase_items cascade;
truncate table purchase_invoices cascade;
truncate table expenses cascade;
truncate table products cascade;
truncate table categories cascade;
truncate table customers cascade;
truncate table suppliers cascade;
truncate table cashiers cascade;
truncate table admin_users cascade;
truncate table employees cascade;
truncate table employee_transactions cascade;
truncate table employee_leaves cascade;

-- إعدادات المتجر (ADRIA بوتيك الأزياء)
delete from store_settings;
insert into store_settings (name, currency, tax_rate, theme_color, initial_balance, address, phone, receipt_header, receipt_footer)
values ('ADRIA - بوتيك الملابس والأزياء', 'ج.م', 0, '#4f46e5', 15000, 'القاهرة - المعادي - شارع النصر', '01000000000', 'أهلاً بكم في بوتيك أدريا للأزياء والملابس', 'شكراً لزيارتكم أدريا نتمنى لكم تجربة تسوق رائعة');

-- 1. تصنيفات بوتيك الملابس
insert into categories (id, name) values
  ('c1000000-0000-0000-0000-000000000001', 'قطاعي'),
  ('c2000000-0000-0000-0000-000000000002', 'جملة'),
  ('c3000000-0000-0000-0000-000000000003', 'نص جملة'),
  ('c4000000-0000-0000-0000-000000000004', 'صيفي'),
  ('c5000000-0000-0000-0000-000000000005', 'شتوي'),
  ('c6000000-0000-0000-0000-000000000006', 'سنوي'),
  ('c7000000-0000-0000-0000-000000000007', 'الموسم'),
  ('c8000000-0000-0000-0000-000000000008', 'التل'),
  ('c9000000-0000-0000-0000-000000000009', 'مسلي'),
  ('ca000000-0000-0000-0000-000000000010', 'jeans'),
  ('cb000000-0000-0000-0000-000000000011', 'موحد');

-- 2. قائمة شاملة بالمنتجات والموديلات (30+ منتج مع كميات العرض والمخزن)
insert into products (id, name, barcode, purchase_price, average_purchase_price, sale_price, wholesale_price, half_wholesale_price, stock_quantity, display_quantity, category_id) values
  ('f1000000-0000-0000-0000-000000000001', 'afra pants', '2001', 400, 400, 650, 550, 600, 10, 4, 'ca000000-0000-0000-0000-000000000010'),
  ('f1000000-0000-0000-0000-000000000002', 'adidas set', '2002', 800, 800, 1290, 1100, 1200, 8, 5, 'c7000000-0000-0000-0000-000000000007'),
  ('f1000000-0000-0000-0000-000000000003', '2 بلوزة تومي', '2003', 380, 380, 600, 500, 550, 12, 6, 'c1000000-0000-0000-0000-000000000001'),
  ('f1000000-0000-0000-0000-000000000004', '-بلوزة كم مروحه', '2004', 420, 420, 690, 580, 630, 15, 8, 'c4000000-0000-0000-0000-000000000004'),
  ('f1000000-0000-0000-0000-000000000005', 'aura 1173', '2005', 450, 450, 690, 580, 630, 14, 7, 'c8000000-0000-0000-0000-000000000008'),
  ('f1000000-0000-0000-0000-000000000006', 'aura 1159', '2006', 600, 600, 950, 800, 870, 6, 3, 'c5000000-0000-0000-0000-000000000005'),
  ('f1000000-0000-0000-0000-000000000007', 'aura 021', '2007', 180, 180, 300, 240, 270, 25, 18, 'c9000000-0000-0000-0000-000000000009'),
  ('f1000000-0000-0000-0000-000000000008', 'afra top lenin', '2008', 150, 150, 250, 200, 220, 20, 12, 'c4000000-0000-0000-0000-000000000004'),
  ('f1000000-0000-0000-0000-000000000009', 'AURA CHEMISE 1003', '2009', 500, 500, 750, 640, 690, 10, 5, 'c6000000-0000-0000-0000-000000000006'),
  ('f1000000-0000-0000-0000-000000000010', 'aura 309', '2010', 380, 380, 590, 490, 540, 16, 9, 'c7000000-0000-0000-0000-000000000007'),
  ('f1000000-0000-0000-0000-000000000011', 'aura 2258', '2011', 280, 280, 450, 370, 410, 20, 11, 'c1000000-0000-0000-0000-000000000001'),
  ('f1000000-0000-0000-0000-000000000012', 'aura 1177', '2012', 450, 450, 690, 580, 630, 12, 6, 'c5000000-0000-0000-0000-000000000005'),
  ('f1000000-0000-0000-0000-000000000013', 'aura open hoodie 2', '2013', 400, 400, 620, 520, 570, 15, 8, 'c5000000-0000-0000-0000-000000000005'),
  ('f1000000-0000-0000-0000-000000000014', 'aura hodie micky', '2014', 420, 420, 650, 540, 590, 18, 10, 'c5000000-0000-0000-0000-000000000005'),
  ('f1000000-0000-0000-0000-000000000015', 'aura collection', '2015', 550, 550, 850, 720, 780, 12, 7, 'c7000000-0000-0000-0000-000000000007'),
  ('f1000000-0000-0000-0000-000000000016', 'AURA CHEMISE CAROH24', '2016', 480, 480, 720, 600, 660, 11, 6, 'c6000000-0000-0000-0000-000000000006'),
  ('f1000000-0000-0000-0000-000000000017', 'جاكيت جينز زارا', '2017', 500, 500, 790, 650, 720, 15, 8, 'ca000000-0000-0000-0000-000000000010'),
  ('f1000000-0000-0000-0000-000000000018', 'بناطيل ميلتون أورورا', '2018', 250, 250, 390, 320, 350, 30, 15, 'cb000000-0000-0000-0000-000000000011'),
  ('f1000000-0000-0000-0000-000000000019', 'فستان سهرة لوريكس', '2019', 900, 900, 1450, 1200, 1300, 8, 4, 'c8000000-0000-0000-0000-000000000008'),
  ('f1000000-0000-0000-0000-000000000020', 'تيشيرت قطن أوفر سايز', '2020', 180, 180, 290, 230, 260, 35, 20, 'c4000000-0000-0000-0000-000000000004'),
  ('f1000000-0000-0000-0000-000000000021', 'كارديجان صوف شتوي', '2021', 450, 450, 720, 600, 650, 12, 6, 'c5000000-0000-0000-0000-000000000005'),
  ('f1000000-0000-0000-0000-000000000022', 'بنطلون جينز بويفريند', '2022', 350, 350, 550, 450, 500, 20, 10, 'ca000000-0000-0000-0000-000000000010'),
  ('f1000000-0000-0000-0000-000000000023', 'بلوزة ستان سواريه', '2023', 320, 320, 520, 420, 470, 14, 7, 'c1000000-0000-0000-0000-000000000001'),
  ('f1000000-0000-0000-0000-000000000024', 'سويت شيرت كابيشون', '2024', 380, 380, 590, 490, 540, 16, 9, 'c5000000-0000-0000-0000-000000000005'),
  ('f1000000-0000-0000-0000-000000000025', 'ترينج أديداس 3 قطع', '2025', 750, 750, 1190, 980, 1080, 10, 5, 'c7000000-0000-0000-0000-000000000007'),
  ('f1000000-0000-0000-0000-000000000026', 'قميص لينن أبيض', '2026', 280, 280, 450, 370, 410, 22, 12, 'c4000000-0000-0000-0000-000000000004'),
  ('f1000000-0000-0000-0000-000000000027', 'جاكيت بامب ووتربروف', '2027', 850, 850, 1350, 1100, 1220, 8, 4, 'c5000000-0000-0000-0000-000000000005'),
  ('f1000000-0000-0000-0000-000000000028', 'شورت جينز كاجوال', '2028', 220, 220, 360, 290, 320, 25, 14, 'ca000000-0000-0000-0000-000000000010'),
  ('f1000000-0000-0000-0000-000000000029', 'فستان مشجر صيفي', '2029', 350, 350, 580, 480, 530, 15, 8, 'c4000000-0000-0000-0000-000000000004'),
  ('f1000000-0000-0000-0000-000000000030', 'طقم بيجامة ستان 4 قطع', '2030', 420, 420, 680, 550, 610, 12, 6, 'c9000000-0000-0000-0000-000000000009');

-- 3. العملاء والموردين
insert into customers (id, custom_id, name, phone, card_number, address) values
  ('d1000000-0000-0000-0000-000000000001', 'CUST-101', 'أحمد محمود العبد', '01012345678', '1001', 'المعادي - القاهرة'),
  ('d1000000-0000-0000-0000-000000000002', 'CUST-102', 'سارة خالد', '01198765432', '1002', 'مدينة نصر - القاهرة'),
  ('d1000000-0000-0000-0000-000000000003', 'CUST-103', 'شركة الأمل للأزياء', '01234567890', '1003', 'التجمع الخامس');

insert into suppliers (id, name, phone, address) values
  ('e1000000-0000-0000-0000-000000000001', 'مؤسسة أورا للأزياء والملابس', '01000111222', 'القاهرة - التوفيقية'),
  ('e1000000-0000-0000-0000-000000000002', 'شركة عفراء للنسيج والغزل', '01111222333', 'الإسكندرية');

-- 4. الكاشيرية ومدراء لوحة التحكم
insert into cashiers (id, name, password, email, phone, full_access) values
  ('a1000000-0000-0000-0000-000000000001', 'كاشير ديمو', '1234', 'cashier@demo.com', '01000000000', true);

insert into admin_users (id, name, password, email, permissions) values
  ('a2000000-0000-0000-0000-000000000001', 'مدير ديمو', '1234', 'admin@demo.com', '[]'::jsonb);

insert into employees (id, name, job_title, working_hours, monthly_salary, annual_leave_balance, is_active) values
  ('b1000000-0000-0000-0000-000000000001', 'موظف ديمو', 'كاشير ومحاسب', '8 ساعات', 5000, 21, true);

-- 5. فواتير مبيعات ديمو مكتملة (تغذي شاشات النظرة العامة والتقارير)
insert into orders (id, total, paid_amount, paid_cash, paid_visa, paid_wallet, paid_instapay, payment_method, type, customer_id, cashier_name, created_at) values
  ('1', 1300, 1300, 1300, 0, 0, 0, 'cash', 'sale', 'd1000000-0000-0000-0000-000000000001', 'كاشير ديمو', now() - interval '3 days'),
  ('2', 1290, 1290, 0, 1290, 0, 0, 'visa', 'sale', 'd1000000-0000-0000-0000-000000000002', 'كاشير ديمو', now() - interval '2 days'),
  ('3', 1500, 1500, 1500, 0, 0, 0, 'cash', 'sale', 'd1000000-0000-0000-0000-000000000001', 'كاشير ديمو', now() - interval '1 day'),
  ('4', 2140, 2140, 0, 0, 2140, 0, 'wallet', 'sale', 'd1000000-0000-0000-0000-000000000003', 'كاشير ديمو', now() - interval '5 hours');

insert into invoice_counter (id, current_value) values (1, 5) on conflict (id) do update set current_value = 5;

insert into order_items (order_id, product_id, product_name, barcode, quantity, sale_price, purchase_price) values
  ('1', 'f1000000-0000-0000-0000-000000000001', 'afra pants', '2001', 2, 650, 400),
  ('2', 'f1000000-0000-0000-0000-000000000002', 'adidas set', '2002', 1, 1290, 800),
  ('3', 'f1000000-0000-0000-0000-000000000009', 'AURA CHEMISE 1003', '2009', 2, 750, 500),
  ('4', 'f1000000-0000-0000-0000-000000000025', 'ترينج أديداس 3 قطع', '2025', 1, 1190, 750),
  ('4', 'f1000000-0000-0000-0000-000000000006', 'aura 1159', '2006', 1, 950, 600);

-- 6. مصروفات ديمو
insert into expenses (category, amount, note, payment_method, paid_cash, created_at) values
  ('إيجار البوتيك', 5000, 'إيجار المحل الشهري', 'cash', 5000, now() - interval '3 days'),
  ('كهرباء وتكييف', 1200, 'فاتورة الكهرباء للتكييفات', 'cash', 1200, now() - interval '1 day');

-- =============================================================================
-- تم إعداد قاعدة البيانات وتغذية كافة شاشات ولوحة التحكم بمنتجات وتصنيفات أدريا للأزياء.
-- =============================================================================
