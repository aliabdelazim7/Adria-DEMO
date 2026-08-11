-- =============================================================================
-- ADRIA — تصفير المستخدمين وإضافة مستخدمين ديمو للعملاء الجدد
-- شغّله في Supabase → SQL Editor لتصفير اليوزارات وإعادة تعيين حسابات التجربة (Demo)
-- =============================================================================

-- 1. مسح المستخدمين الحاليين (المحاسبين / الكاشيرية، مدراء النظام، الموظفين)
TRUNCATE TABLE cashiers CASCADE;
TRUNCATE TABLE admin_users CASCADE;
TRUNCATE TABLE employees CASCADE;

-- 2. إدخال كاشيرية ديمو للتجربة
INSERT INTO cashiers (id, name, password, email, phone, full_access) VALUES
  (gen_random_uuid(), 'كاشير 1 (أحمد)', '1234', 'cashier1@demo.local', '01000000001', true),
  (gen_random_uuid(), 'كاشير 2 (سارة)', '1234', 'cashier2@demo.local', '01000000002', false);

-- 3. إدخال مدراء لوحة التحكم ديمو للتجربة
INSERT INTO admin_users (id, name, password, email, permissions) VALUES
  (gen_random_uuid(), 'مدير النظام التجريبي', '1234', 'admin-demo@demo.local', '[]'::jsonb);

-- 4. إدخال موظفين تجريبيين لإدارات الرواتب والحضور
INSERT INTO employees (id, name, job_title, working_hours, monthly_salary, annual_leave_balance, is_active) VALUES
  (gen_random_uuid(), 'محمد علي (موظف ديمو)', 'كاشير رئيسي', '8 ساعات', 5000, 21, true),
  (gen_random_uuid(), 'مريم محمود (موظف ديمو)', 'محاسب', '8 ساعات', 6000, 21, true);

-- 5. إعادة التأكد من صلاحيات RPC لشاشات الدخول
GRANT EXECUTE ON FUNCTION public.get_pos_login_data() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_login_data() TO anon, authenticated;
