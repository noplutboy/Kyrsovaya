USE master;
GO
-- 1. Создаем логин (пароль 12345)
CREATE LOGIN kurs_admin WITH PASSWORD = '12345';
GO

-- 2. Переходим в твою базу
USE CRM_Orders_DB;
GO

-- 3. Создаем пользователя внутри базы и привязываем к логину
CREATE USER kurs_admin FOR LOGIN kurs_admin;
GO

-- 4. Даем ему права "хозяина" базы (чтобы мог читать и писать)
ALTER ROLE db_owner ADD MEMBER kurs_admin;
GO