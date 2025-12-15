------------------------------------------------------
-- 1. Определяем товары без продаж
------------------------------------------------------
WITH UnsoldProducts AS (
    SELECT ProductID, Name, Price
    FROM Products
    WHERE ProductID NOT IN (SELECT DISTINCT ProductID FROM OrderDetails)
)
SELECT * FROM UnsoldProducts;

------------------------------------------------------
-- 2. Добавляем новые заказы для этих товаров
------------------------------------------------------
-- Используем существующих клиентов (берём первые несколько)
-- Для каждого товара создаём отдельный заказ
INSERT INTO Orders (CustomerID, Status)
SELECT TOP 7 CustomerID, 'New'
FROM Customers
ORDER BY CustomerID;  -- просто берём первых 7 клиентов

------------------------------------------------------
-- 3. Добавляем детали заказов для товаров, которые не продавались
------------------------------------------------------
-- Узнаём OrderID последних 7 заказов
WITH LastOrders AS (
    SELECT TOP 7 OrderID
    FROM Orders
    ORDER BY OrderID DESC
),
UnsoldProducts AS (
    SELECT ProductID, Price
    FROM Products
    WHERE ProductID NOT IN (SELECT DISTINCT ProductID FROM OrderDetails)
)
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
SELECT o.OrderID, p.ProductID, 1, p.Price
FROM LastOrders o
CROSS JOIN UnsoldProducts p;

------------------------------------------------------
-- 4. Пересчёт суммы для всех заказов
------------------------------------------------------
UPDATE Orders
SET TotalAmount = (
    SELECT SUM(Quantity * UnitPrice)
    FROM OrderDetails
    WHERE OrderDetails.OrderID = Orders.OrderID
);
