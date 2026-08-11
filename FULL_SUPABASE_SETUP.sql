-- =============================================================================
-- ADRIA — إعداد قاعدة البيانات الشاملة مع كامل بيانات الديمو التوضيحية
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
  name text not null default 'مركز أدريا لقطع غيار السيارات والصيانة',
  currency text default 'ج.م',
  logo text default 'https://cdn-icons-png.flaticon.com/512/3143/3143641.png',
  tax_rate numeric default 0,
  theme_color text default '#4f46e5',
  address text default 'القاهرة - حي المعادي - شارع النصر',
  phone text default '01000000000',
  phone2 text default '01100000000',
  whatsapp_country_code text default '2',
  initial_balance numeric default 15000,
  location_url text default '',
  allow_cashier_employee_advance boolean default true,
  day_start_hour integer default 3,
  receipt_header text default 'أهلاً بكم في مركز أدريا لقطع غيار السيارات',
  receipt_footer text default 'شكراً لزيارتكم نتمنى لكم رحلة آمنة'
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

-- ---------- (5) تصفير الجداول وتغذية بيانات الديمو الكاملة ----------

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
truncate table car_subscriptions cascade;
truncate table maintenance_appointments cascade;

-- إعدادات المحل
delete from store_settings;
insert into store_settings (name, currency, tax_rate, theme_color, initial_balance, address, phone, receipt_header, receipt_footer)
values ('مركز أدريا لقطع غيار السيارات والصيانة', 'ج.م', 0, '#4f46e5', 15000, 'القاهرة - المعادي - شارع النصر', '01000000000', 'أهلاً بكم في مركز أدريا لقطع غيار السيارات', 'شكراً لزيارتكم نتمنى لكم رحلة آمنة');

-- 1. التصنيفات
insert into categories (id, name) values
  ('c1000000-0000-0000-0000-000000000001', 'فلاتر وزيوت'),
  ('c2000000-0000-0000-0000-000000000002', 'فرامل ونظام تعليق'),
  ('c3000000-0000-0000-0000-000000000003', 'كهرباء وبطاريات'),
  ('c4000000-0000-0000-0000-000000000004', 'محركات وميكانيكا'),
  ('c5000000-0000-0000-0000-000000000005', 'إضاءة وكشافات'),
  ('c6000000-0000-0000-0000-000000000006', 'إكسسوارات وكماليات');

-- 2. المنتجات (مع UUIDs صحيحة هكس ديسيمال)
insert into products (id, name, barcode, purchase_price, average_purchase_price, sale_price, stock_quantity, category_id) values
  ('f1000000-0000-0000-0000-000000000001', 'تيل فرامل أمامي كوري', '1001', 450, 450, 650, 18, 'c2000000-0000-0000-0000-000000000002'),
  ('f1000000-0000-0000-0000-000000000002', 'فلتر زيت تويوتا أصلي', '1002', 120, 120, 180, 42, 'c1000000-0000-0000-0000-000000000001'),
  ('f1000000-0000-0000-0000-000000000003', 'طقم بوجيهات NGK ليزر', '1003', 350, 350, 480, 12, 'c3000000-0000-0000-0000-000000000003'),
  ('f1000000-0000-0000-0000-000000000004', 'سير كاتينة دايكو', '1004', 280, 280, 420, 8,  'c4000000-0000-0000-0000-000000000004'),
  ('f1000000-0000-0000-0000-000000000005', 'مساعد خلفي KYB', '1005', 850, 850, 1100, 2,  'c2000000-0000-0000-0000-000000000002'), -- منخفض للمخزون (2)
  ('f1000000-0000-0000-0000-000000000006', 'بطارية كلورايد 70 أمبير', '1006', 1800, 1800, 2400, 5, 'c3000000-0000-0000-0000-000000000003'),
  ('f1000000-0000-0000-0000-000000000007', 'طلمبة بنزين بوش', '1007', 650, 650, 950, 1,  'c4000000-0000-0000-0000-000000000004'), -- منخفض للمخزون (1)
  ('f1000000-0000-0000-0000-000000000008', 'فلتر هواء هيونداي', '1008', 150, 150, 220, 25, 'c1000000-0000-0000-0000-000000000001'),
  ('f1000000-0000-0000-0000-000000000009', 'زيت محرك توتال 5W-30 (4L)', '1009', 850, 850, 1150, 20, 'c1000000-0000-0000-0000-000000000001'),
  ('f1000000-0000-0000-0000-000000000010', 'فانوس أمامي ليد', '1010', 1100, 1100, 1600, 6, 'c5000000-0000-0000-0000-000000000005'),
  ('f1000000-0000-0000-0000-000000000011', 'مساحات زجاج أمامي (طقم)', '1011', 130, 130, 230, 35, 'c6000000-0000-0000-0000-000000000006');

-- 3. العملاء
insert into customers (id, custom_id, name, phone, card_number, address) values
  ('d1000000-0000-0000-0000-000000000001', 'CUST-101', 'أحمد محمود العبد', '01012345678', '1001', 'المعادي - القاهرة'),
  ('d1000000-0000-0000-0000-000000000002', 'CUST-102', 'المهندس خالد حسن', '01198765432', '1002', 'مدينة نصر - القاهرة'),
  ('d1000000-0000-0000-0000-000000000003', 'CUST-103', 'شركة الأمل للنقل', '01234567890', '1003', 'التجمع الخامس'),
  ('d1000000-0000-0000-0000-000000000004', 'CUST-104', 'سامح توفيق', '01055554444', '1004', 'الجيزة');

-- 4. الموردين
insert into suppliers (id, name, phone, address) values
  ('e1000000-0000-0000-0000-000000000001', 'شركة البوش لقطع الغيار', '01000111222', 'العتبة - القاهرة'),
  ('e1000000-0000-0000-0000-000000000002', 'مؤسسة الكوري للأجزاء الأصلية', '01111222333', 'توفيقية - القاهرة');

-- 5. الكاشيرية ومدراء اللوحة
insert into cashiers (id, name, password, email, phone, full_access) values
  ('a1000000-0000-0000-0000-000000000001', 'كاشير 1 (أحمد)', '1234', 'cashier1@demo.local', '01000000001', true),
  ('a1000000-0000-0000-0000-000000000002', 'كاشير 2 (سارة)', '1234', 'cashier2@demo.local', '01000000002', false);

insert into admin_users (id, name, password, email, permissions) values
  ('a2000000-0000-0000-0000-000000000001', 'مدير النظام التجريبي', '1234', 'admin-demo@demo.local', '[]'::jsonb);

-- 6. الموظفين
insert into employees (id, name, job_title, working_hours, monthly_salary, annual_leave_balance, is_active) values
  ('b1000000-0000-0000-0000-000000000001', 'محمد علي (موظف ديمو)', 'كاشير رئيسي', '8 ساعات', 5000, 21, true),
  ('b1000000-0000-0000-0000-000000000002', 'مريم محمود (موظف ديمو)', 'محاسب', '8 ساعات', 6000, 21, true);

-- 7. فواتير مبيعات ديمو مكتملة (تغذي شاشة النظرة العامة، الفواتير، التقارير)
insert into orders (id, total, paid_amount, paid_cash, paid_visa, paid_wallet, paid_instapay, payment_method, type, customer_id, cashier_name, created_at) values
  ('1', 1300, 1300, 1300, 0, 0, 0, 'cash', 'sale', 'd1000000-0000-0000-0000-000000000001', 'كاشير 1 (أحمد)', now() - interval '3 days'),
  ('2', 2850, 2850, 0, 2850, 0, 0, 'visa', 'sale', 'd1000000-0000-0000-0000-000000000002', 'كاشير 1 (أحمد)', now() - interval '2 days'),
  ('3', 4400, 4400, 0, 0, 0, 4400, 'instapay', 'sale', 'd1000000-0000-0000-0000-000000000003', 'كاشير 2 (سارة)', now() - interval '2 days'),
  ('4', 1950, 1950, 1950, 0, 0, 0, 'cash', 'sale', 'd1000000-0000-0000-0000-000000000004', 'كاشير 1 (أحمد)', now() - interval '1 day'),
  ('5', 3600, 3600, 0, 0, 3600, 0, 'wallet', 'sale', 'd1000000-0000-0000-0000-000000000001', 'كاشير 2 (سارة)', now() - interval '1 day'),
  ('6', 5200, 5200, 5200, 0, 0, 0, 'cash', 'sale', 'd1000000-0000-0000-0000-000000000002', 'كاشير 1 (أحمد)', now() - interval '5 hours'),
  ('7', 850,  850,  850,  0, 0, 0, 'cash', 'sale', 'd1000000-0000-0000-0000-000000000003', 'كاشير 2 (سارة)', now() - interval '3 hours'),
  ('8', 6100, 6100, 0, 0, 0, 6100, 'instapay', 'sale', 'd1000000-0000-0000-0000-000000000004', 'كاشير 1 (أحمد)', now() - interval '1 hour');

-- ضبط عداد الفواتير
insert into invoice_counter (id, current_value) values (1, 9) on conflict (id) do update set current_value = 9;

-- بنود فواتير المبيعات
insert into order_items (order_id, product_id, product_name, barcode, quantity, sale_price, purchase_price) values
  ('1', 'f1000000-0000-0000-0000-000000000001', 'تيل فرامل أمامي كوري', '1001', 2, 650, 450),
  ('2', 'f1000000-0000-0000-0000-000000000009', 'زيت محرك توتال 5W-30 (4L)', '1009', 2, 1150, 850),
  ('2', 'f1000000-0000-0000-0000-000000000002', 'فلتر زيت تويوتا أصلي', '1002', 3, 180, 120),
  ('3', 'f1000000-0000-0000-0000-000000000006', 'بطارية كلورايد 70 أمبير', '1006', 1, 2400, 1800),
  ('3', 'f1000000-0000-0000-0000-000000000010', 'فانوس أمامي ليد', '1010', 1, 1600, 1100),
  ('3', 'f1000000-0000-0000-0000-000000000004', 'سير كاتينة دايكو', '1004', 1, 420, 280),
  ('4', 'f1000000-0000-0000-0000-000000000003', 'طقم بوجيهات NGK ليزر', '1003', 3, 480, 350),
  ('4', 'f1000000-0000-0000-0000-000000000011', 'مساحات زجاج أمامي (طقم)', '1011', 2, 230, 130),
  ('5', 'f1000000-0000-0000-0000-000000000005', 'مساعد خلفي KYB', '1005', 3, 1100, 850),
  ('5', 'f1000000-0000-0000-0000-000000000008', 'فلتر هواء هيونداي', '1008', 1, 220, 150),
  ('6', 'f1000000-0000-0000-0000-000000000006', 'بطارية كلورايد 70 أمبير', '1006', 2, 2400, 1800),
  ('6', 'f1000000-0000-0000-0000-000000000004', 'سير كاتينة دايكو', '1004', 1, 420, 280),
  ('7', 'f1000000-0000-0000-0000-000000000001', 'تيل فرامل أمامي كوري', '1001', 1, 650, 450),
  ('7', 'f1000000-0000-0000-0000-000000000008', 'فلتر هواء هيونداي', '1008', 1, 220, 150),
  ('8', 'f1000000-0000-0000-0000-000000000007', 'طلمبة بنزين بوش', '1007', 4, 950, 650),
  ('8', 'f1000000-0000-0000-0000-000000000010', 'فانوس أمامي ليد', '1010', 1, 1600, 1100),
  ('8', 'f1000000-0000-0000-0000-000000000003', 'طقم بوجيهات NGK ليزر', '1003', 1, 480, 350);

-- 8. مصروفات ديمو
insert into expenses (category, amount, note, payment_method, paid_cash, created_at) values
  ('إيجار المحل', 4000, 'إيجار شهر الحالي', 'cash', 4000, now() - interval '4 days'),
  ('كهرباء ومياه', 850, 'فاتورة الكهرباء المجمعة', 'cash', 850, now() - interval '2 days'),
  ('ضيافة ومستلزمات', 320, 'شاي وقهوة وضيافة العملاء', 'cash', 320, now() - interval '1 day');

-- 9. معاملة رواتب ديمو
insert into employee_transactions (employee_id, amount, type, payment_method, paid_cash, month, note, created_at) values
  ('b1000000-0000-0000-0000-000000000001', 1000, 'advance', 'cash', 1000, to_char(current_date, 'YYYY-MM'), 'سلفة على راتب الشهر', now() - interval '3 days');

-- =============================================================================
-- تم إعداد قاعدة البيانات وتغذية كافة شاشات ولوحة التحكم بالبيانات العرضية.
-- =============================================================================
