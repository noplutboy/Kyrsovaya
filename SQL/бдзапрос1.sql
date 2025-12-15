-- 1. Создать базу
IF DB_ID('CRM_Orders_DB') IS NULL
BEGIN
    CREATE DATABASE CRM_Orders_DB;
END
