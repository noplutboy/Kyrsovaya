USE CRM_Orders_DB;

---------------------------------------------------
-- 2. Таблица Customers
---------------------------------------------------
CREATE TABLE dbo.Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    Email VARCHAR(150),
    Phone VARCHAR(30),
    CreatedAt DATETIME DEFAULT GETDATE()
);

---------------------------------------------------
-- 3. Таблица Products
---------------------------------------------------
CREATE TABLE dbo.Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(200) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Stock INT NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE()
);

---------------------------------------------------
-- 4. Таблица Orders
---------------------------------------------------
CREATE TABLE dbo.Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    TotalAmount DECIMAL(12,2) DEFAULT 0,
    Status VARCHAR(30) DEFAULT 'New',
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

---------------------------------------------------
-- 5. Таблица OrderDetails
---------------------------------------------------
CREATE TABLE dbo.OrderDetails (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(12,2) NOT NULL,
    LineTotal AS (Quantity * UnitPrice) PERSISTED,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

---------------------------------------------------
-- 6. Таблица Payments
---------------------------------------------------
CREATE TABLE dbo.Payments (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    Amount DECIMAL(12,2) NOT NULL,
    PaymentDate DATETIME DEFAULT GETDATE(),
    Method VARCHAR(50),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);

---------------------------------------------------
-- 7. Тестовые данные (казахстанские)
---------------------------------------------------
INSERT INTO Customers (FirstName, LastName, Email, Phone) VALUES
('Диас',  'Абилов',    'dias@mail.kz',     '+77071234567'),
('Аружан','Серикова',  'aruzhan@mail.kz',  '+77075556677'),
('Максат','Тлеуберген','maksat@mail.kz',   '+77074443322');

INSERT INTO Products (Name, Price, Stock) VALUES
('Ноутбук Lenovo', 299000, 15),
('Смартфон Samsung', 199000, 30),
('Наушники JBL', 29900, 100);

---------------------------------------------------
-- 8. Создаём заказ
---------------------------------------------------
INSERT INTO Orders (CustomerID, Status) VALUES (1, 'New');

---------------------------------------------------
-- 9. Детали заказа
---------------------------------------------------
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES
(1,1,1,299000),
(1,3,2,29900);

---------------------------------------------------
-- 10. Обновляем сумму заказа
---------------------------------------------------
UPDATE Orders
SET TotalAmount = (SELECT SUM(LineTotal) FROM OrderDetails WHERE OrderID = Orders.OrderID)
WHERE OrderID = 1;

---------------------------------------------------
-- 11. Платёж
---------------------------------------------------
INSERT INTO Payments (OrderID, Amount, Method)
VALUES (1, 150000, 'Kaspi QR');
