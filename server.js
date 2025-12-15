const express = require('express');
const sql = require('mssql');
const path = require('path');
const app = express();

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const config = {
    user: 'kurs_admin',
    password: '12345',
    server: 'localhost',
    database: 'CRM_Orders_DB',
    options: { encrypt: false, trustServerCertificate: true }
};

// --- GET ЗАПРОСЫ ---

app.get('/api/admin/customers', async(req, res) => {
    try {
        let pool = await sql.connect(config);
        let result = await pool.request().query('SELECT * FROM Customers ORDER BY CreatedAt DESC');
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/auth/customers', async(req, res) => {
    try {
        let pool = await sql.connect(config);
        let result = await pool.request().query('SELECT CustomerID, FirstName, LastName FROM Customers ORDER BY LastName');
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/admin/stats', async(req, res) => {
    try {
        let pool = await sql.connect(config);
        let query = `
            SELECT 
                (SELECT COUNT(*) FROM Customers) as ClientsCount,
                (SELECT COUNT(*) FROM Orders) as OrdersCount,
                (SELECT SUM(TotalAmount) FROM Orders) as TotalRevenue,
                (SELECT TOP 1 p.Name FROM OrderDetails od JOIN Products p ON od.ProductID = p.ProductID GROUP BY p.Name ORDER BY COUNT(*) DESC) as TopProduct
        `;
        let result = await pool.request().query(query);
        res.json(result.recordset[0]);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/admin/orders', async(req, res) => {
    try {
        let pool = await sql.connect(config);
        let query = `
            SELECT 
                o.OrderID, c.FirstName, c.LastName, o.OrderDate, o.TotalAmount, o.Status,
                STRING_AGG(p.Name, ', ') WITHIN GROUP (ORDER BY p.Name) AS ProductList
            FROM Orders o
            JOIN Customers c ON o.CustomerID = c.CustomerID
            LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
            LEFT JOIN Products p ON od.ProductID = p.ProductID
            GROUP BY o.OrderID, c.FirstName, c.LastName, o.OrderDate, o.TotalAmount, o.Status
            ORDER BY o.OrderDate DESC
        `;
        let result = await pool.request().query(query);
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/client/:id/orders', async(req, res) => {
    try {
        let clientId = req.params.id;
        let pool = await sql.connect(config);
        let query = `
            SELECT o.OrderID, o.OrderDate, o.TotalAmount, o.Status,
                STRING_AGG(p.Name, ', ') WITHIN GROUP (ORDER BY p.Name) AS ProductList
            FROM Orders o
            LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
            LEFT JOIN Products p ON od.ProductID = p.ProductID
            WHERE o.CustomerID = @id
            GROUP BY o.OrderID, o.OrderDate, o.TotalAmount, o.Status
            ORDER BY o.OrderDate DESC
        `;
        let result = await pool.request().input('id', sql.Int, clientId).query(query);
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/client/:id/info', async(req, res) => {
    try {
        let clientId = req.params.id;
        let pool = await sql.connect(config);
        let result = await pool.request().input('id', sql.Int, clientId).query('SELECT * FROM Customers WHERE CustomerID = @id');
        res.json(result.recordset[0]);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/products', async(req, res) => {
    try {
        let pool = await sql.connect(config);
        let result = await pool.request().query('SELECT * FROM Products ORDER BY Price ASC');
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- POST/DELETE (АДМИН) ---

app.post('/api/products', async(req, res) => {
    try {
        let { name, price, stock } = req.body;
        let pool = await sql.connect(config);
        await pool.request()
            .input('name', sql.VarChar, name).input('price', sql.Decimal, price).input('stock', sql.Int, stock)
            .query('INSERT INTO Products (Name, Price, Stock) VALUES (@name, @price, @stock)');
        res.json({ message: 'Success' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/products/:id', async(req, res) => {
    try {
        let id = req.params.id;
        let pool = await sql.connect(config);
        await pool.request().input('id', sql.Int, id).query('DELETE FROM Products WHERE ProductID = @id');
        res.json({ message: 'Deleted' });
    } catch (err) { res.status(500).json({ error: 'Товар нельзя удалить, он есть в заказах!' }); }
});

app.post('/api/customers', async(req, res) => {
    try {
        let { firstName, lastName, email, phone } = req.body;
        let pool = await sql.connect(config);
        await pool.request()
            .input('fn', sql.VarChar, firstName).input('ln', sql.VarChar, lastName).input('em', sql.VarChar, email).input('ph', sql.VarChar, phone)
            .query('INSERT INTO Customers (FirstName, LastName, Email, Phone) VALUES (@fn, @ln, @em, @ph)');
        res.json({ message: 'Success' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- ОФОРМЛЕНИЕ ЗАКАЗА ---
app.post('/api/orders/create', async(req, res) => {
    try {
        const { customerId, productId, price, method } = req.body;
        let pool = await sql.connect(config);

        // 1. Создаем заказ
        let orderResult = await pool.request()
            .input('cid', sql.Int, customerId)
            .query("INSERT INTO Orders (CustomerID, Status, TotalAmount) OUTPUT INSERTED.OrderID VALUES (@cid, 'New', 0)");

        let newOrderId = orderResult.recordset[0].OrderID;

        // 2. Добавляем товар
        await pool.request()
            .input('oid', sql.Int, newOrderId)
            .input('pid', sql.Int, productId)
            .input('price', sql.Decimal, price)
            .query("INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@oid, @pid, 1, @price)");

        // 3. Обновляем сумму
        await pool.request()
            .input('oid', sql.Int, newOrderId)
            .query("UPDATE Orders SET TotalAmount = (SELECT SUM(LineTotal) FROM OrderDetails WHERE OrderID = @oid) WHERE OrderID = @oid");

        // 4. Проводим оплату (Твой триггер в БД сам поставит Paid)
        await pool.request()
            .input('oid', sql.Int, newOrderId)
            .input('amount', sql.Decimal, price)
            .input('method', sql.VarChar, method)
            .query("INSERT INTO Payments (OrderID, Amount, Method) VALUES (@oid, @amount, @method)");

        res.json({ message: 'Order Created', orderId: newOrderId });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: err.message });
    }
});

// --- ЗАПУСК СЕРВЕРА (НАСТРОЕННЫЙ ЛОГ) ---
app.listen(3000, async() => {
    console.log('\n=========================================================');
    console.log('🚀 CRM-СИСТЕМА УСПЕШНО ЗАПУЩЕНА И ГОТОВА К РАБОТЕ!');
    console.log('=========================================================');
    console.log('👤 Автор работы: Кудабаев Сабит | Админ-32');
    console.log('🏠 Ссылка на сайт: http://localhost:3000');
    console.log('---------------------------------------------------------');

    try {
        await sql.connect(config);
        console.log('✅ База данных (SQL Server): Подключено успешно');
        console.log('📊 Статус: Сервер обрабатывает запросы...');
    } catch (e) {
        console.log('❌ ОШИБКА ПОДКЛЮЧЕНИЯ К БАЗЕ:', e.message);
    }
    console.log('=========================================================\n');
});