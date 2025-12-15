------------------------------------------------------
--  Добавляем заказы 2–5
------------------------------------------------------
INSERT INTO Orders (CustomerID, Status) VALUES 
(2, 'New'),   -- заказ 2
(3, 'New'),   -- заказ 3
(1, 'New'),   -- заказ 4
(4, 'New');   -- заказ 5


------------------------------------------------------
--  Добавляем детали заказов
------------------------------------------------------

-- Заказ 2
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES
(2, 2, 1, 250.50),
(2, 3, 3, 75.25);

-- Заказ 3
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES
(3, 1, 1, 1000.00);

-- Заказ 4
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES
(4, 3, 10, 75.25);

-- Заказ 5
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES
(5, 1, 1, 1000.00),
(5, 2, 2, 250.50);


------------------------------------------------------
--  Пересчёт сумм всех заказов
------------------------------------------------------
UPDATE Orders
SET TotalAmount = (
    SELECT SUM(LineTotal)
    FROM OrderDetails
    WHERE OrderID = Orders.OrderID
);


------------------------------------------------------
--  Платежи для части заказов
------------------------------------------------------
INSERT INTO Payments (OrderID, Amount, Method) VALUES
(2, 300.00, 'Kaspi QR'),
(3, 1000.00, 'Card'),
(5, 500.00, 'Cash');
