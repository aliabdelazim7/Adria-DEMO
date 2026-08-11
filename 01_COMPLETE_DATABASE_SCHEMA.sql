-- =============================================================================
-- ADRIA — (1) الهيكل الكامل لقاعدة البيانات (Complete Schema & Functions)
-- انسخ هذا الملف بالكامل واعمل له Run في Supabase SQL Editor لإنشاء كافة الجداول
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
  logo text default '',
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
