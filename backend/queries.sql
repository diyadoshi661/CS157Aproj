WITH SalesSummary AS (
    SELECT
        YEAR(SaleDate) AS Year,
        MONTH(SaleDate) AS Month,
        SUM(TotalRevenue) AS TotalSales
    FROM
        SalesRecords
    WHERE
        (YEAR(SaleDate) = 2023 AND MONTH(SaleDate) = 11) 
        OR (YEAR(SaleDate) = 2024 AND MONTH(SaleDate) IN (11, 10))
    GROUP BY
        YEAR(SaleDate), MONTH(SaleDate)
)
SELECT
    ss1.Year AS CurrentYear,
    ss1.Month AS CurrentMonth,
    ss1.TotalSales AS TotalSales
FROM
    SalesSummary ss1
WHERE
    (ss1.Year = 2024 AND ss1.Month = 11)   -- November 2024
    OR (ss1.Year = 2024 AND ss1.Month = 10)   -- October 2024
    OR (ss1.Year = 2023 AND ss1.Month = 11)   -- November 2023
ORDER BY
    ss1.Year DESC, ss1.Month DESC;

-- Best seller by total revenue
SELECT
    ProductID,
    SUM(TotalRevenue) AS TotalRevenueGenerated
FROM
    SalesRecords
GROUP BY
    ProductID
ORDER BY
	TotalRevenueGenerated DESC
LIMIT 1;


-- Worst seller by total revenue
SELECT
    ProductID,
    SUM(TotalRevenue) AS TotalRevenueGenerated
FROM
    SalesRecords
GROUP BY
    ProductID
ORDER BY
    TotalRevenueGenerated ASC
LIMIT 1;

--Most Profitable Vendor
SELECT
    v.VendorID,
    v.VendorName,
    SUM(sr.TotalRevenue) AS TotalRevenueGenerated
FROM
    Vendors v
JOIN
    Products p ON v.VendorID = p.VendorID  -- Assuming Products are linked to Vendors
JOIN
    SalesRecords sr ON p.ProductID = sr.ProductID  -- Sales are linked to Products
GROUP BY
    v.VendorID, v.VendorName
ORDER BY
    TotalRevenueGenerated DESC
LIMIT 1;


--Least Profitable Vendor 
SELECT
    v.VendorID,
    v.VendorName,
    SUM(sr.TotalRevenue) AS TotalRevenueGenerated
FROM
    Vendors v
JOIN
    Products p ON v.VendorID = p.VendorID
JOIN
    SalesRecords sr ON p.ProductID = sr.ProductID
GROUP BY
    v.VendorID, v.VendorName
ORDER BY
    TotalRevenueGenerated ASC
LIMIT 1;

SELECT p.ProductID, p.ProductName
FROM Products p
LEFT JOIN SalesRecords sr ON p.ProductID = sr.ProductID
AND sr.SaleDate >= CURDATE() - INTERVAL 3 MONTH
WHERE sr.SalesRecordID IS NULL;

--5 QUERIES
SELECT
    c.CustomerID,
    c.CustomerName,
    SUM(sr.TotalRevenue) AS TotalRevenue
FROM
    Customers c
JOIN
    SalesRecords sr ON c.CustomerID = sr.CustomerID
GROUP BY
    c.CustomerID, c.CustomerName
ORDER BY
    TotalRevenue DESC;

SELECT v.VendorID, v.VendorName, COUNT(vo.VendorOrderID) AS TotalVendorOrders
FROM Vendors v
LEFT JOIN VendorOrders vo ON v.VendorID = vo.VendorID
GROUP BY v.VendorID, v.VendorName
ORDER BY TotalVendorOrders DESC;

SELECT o.OrderID, AVG(od.Quantity) AS AverageOrderSize
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY o.OrderID;

SELECT
    CASE
        WHEN MONTH(sr.SaleDate) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN MONTH(sr.SaleDate) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN MONTH(sr.SaleDate) BETWEEN 7 AND 9 THEN 'Q3'
        WHEN MONTH(sr.SaleDate) BETWEEN 10 AND 12 THEN 'Q4'
    END AS Quarter,
    SUM(sr.TotalRevenue) AS TotalRevenue
FROM SalesRecords sr
GROUP BY Quarter
ORDER BY
    CASE Quarter
        WHEN 'Q1' THEN 1
         WHEN 'Q2' THEN 2
        WHEN 'Q3' THEN 3
        WHEN 'Q4' THEN 4
    END;


SELECT c.CustomerID, c.CustomerName, SUM(sr.TotalRevenue) AS TotalSpent
FROM Customers c
JOIN SalesRecords sr ON c.CustomerID = sr.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY TotalSpent DESC
LIMIT 5;

