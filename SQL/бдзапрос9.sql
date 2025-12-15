-----------------------------------------
-- 1. —оздаем 50 заказов
-----------------------------------------

DECLARE @i INT = 1;

WHILE @i <= 50
BEGIN
    INSERT INTO Orders (CustomerID, Status)
    VALUES (
        (SELECT TOP 1 CustomerID FROM Customers ORDER BY NEWID()),  -- случайный клиент
        'New'
    );

    SET @i = @i + 1;
END

-----------------------------------------
-- 2. —оздаем детали заказов (от 1 до 5 товаров)
-----------------------------------------

DECLARE @OrderID INT;
DECLARE @DetailsCount INT;
DECLARE @j INT;

DECLARE OrderCursor CURSOR FOR
    SELECT OrderID FROM Orders;

OPEN OrderCursor;
FETCH NEXT FROM OrderCursor INTO @OrderID;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- сколько товаров будет в заказе (1Ц5)
    SET @DetailsCount = (ABS(CHECKSUM(NEWID())) % 5) + 1;
    SET @j = 1;

    WHILE @j <= @DetailsCount
    BEGIN
        DECLARE @ProdID INT =
            (SELECT TOP 1 ProductID FROM Products ORDER BY NEWID());

        DECLARE @Price DECIMAL(12,2) =
            (SELECT Price FROM Products WHERE ProductID = @ProdID);

        DECLARE @Qty INT =
            (ABS(CHECKSUM(NEWID())) % 5) + 1;  -- количество от 1 до 5

        INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
        VALUES (@OrderID, @ProdID, @Qty, @Price);

        SET @j = @j + 1;
    END

    FETCH NEXT FROM OrderCursor INTO @OrderID;
END

CLOSE OrderCursor;
DEALLOCATE OrderCursor;

-----------------------------------------
-- 3. ѕересчитываем суммы заказов
-----------------------------------------

UPDATE Orders
SET TotalAmount =
(
    SELECT SUM(LineTotal)
    FROM OrderDetails
    WHERE OrderDetails.OrderID = Orders.OrderID
);

-----------------------------------------
-- 4. ƒобавл€ем платежи (частичные или полные)
-----------------------------------------

DECLARE @Amount DECIMAL(14,2);

DECLARE PayCursor CURSOR FOR
    SELECT OrderID, TotalAmount FROM Orders;

OPEN PayCursor;
FETCH NEXT FROM PayCursor INTO @OrderID, @Amount;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- шанс: 70% полна€ оплата, 30% Ч частична€
    DECLARE @Paid DECIMAL(14,2) =
        CASE WHEN ABS(CHECKSUM(NEWID())) % 10 < 7
             THEN @Amount
             ELSE @Amount * 0.5
        END;

    INSERT INTO Payments (OrderID, Amount, Method)
    VALUES (
        @OrderID,
        @Paid,
        CASE ABS(CHECKSUM(NEWID())) % 3
            WHEN 0 THEN 'Card'
            WHEN 1 THEN 'Cash'
            ELSE 'Kaspi'
        END
    );

    FETCH NEXT FROM PayCursor INTO @OrderID, @Amount;
END

CLOSE PayCursor;
DEALLOCATE PayCursor;

-----------------------------------------
-- √ќ“ќ¬ќ
-----------------------------------------
PRINT '50 заказов, детали заказа и платежи успешно созданы!';
