-- =============================================================================
-- ADRIA — تصفير المستخدمين وإضافة مستخدم ديمو
-- شغّله في Supabase → SQL Editor لتصفير اليوزارات وإعادة تعيين حسابات التجربة (Demo)
-- =============================================================================

-- 1. مسح جميع المستخدمين الحاليين (الكاشيرية، مدراء النظام، والموظفين)
TRUNCATE TABLE cashiers CASCADE;
TRUNCATE TABLE admin_users CASCADE;
TRUNCATE TABLE employees CASCADE;

-- 2. إدخال كاشير ديمو للتجربة (نظام الكاشير / POS)
INSERT INTO cashiers (id, name, password, email, phone, full_access) VALUES
  (gen_random_uuid(), 'كاشير ديمو', '1234', 'cashier@demo.com', '01000000000', true);

-- 3. إدخال مدير ديمو للتجربة (لوحة التحكم / Admin)
INSERT INTO admin_users (id, name, password, email, permissions) VALUES
  (gen_random_uuid(), 'مدير ديمو', '1234', 'admin@demo.com', '[]'::jsonb);

-- 4. إدخال موظف ديمو (لإدارة الحضور والرواتب)
INSERT INTO employees (id, name, job_title, working_hours, monthly_salary, annual_leave_balance, is_active) VALUES
  (gen_random_uuid(), 'موظف ديمو', 'كاشير ومحاسب', '8 ساعات', 5000, 21, true);

-- 5. إعطاء الصلاحيات للوظائف
GRANT EXECUTE ON FUNCTION public.get_pos_login_data() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_login_data() TO anon, authenticated;
