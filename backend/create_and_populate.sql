-- Step 1: Create the database
CREATE DATABASE IF NOT EXISTS InventoryManagement;
USE InventoryManagement;

-- Step 2: Create tables in the correct order

-- Vendors table
CREATE TABLE Vendors (
    VendorID INT AUTO_INCREMENT PRIMARY KEY,
    VendorName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE
);

-- Customers table
CREATE TABLE Customers (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE
);

-- Products table (simplified as per your request)
CREATE TABLE Products (
    ProductID INT AUTO_INCREMENT PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    ReorderThreshold INT NOT NULL DEFAULT 5,
    UnitPrice DECIMAL(10, 2) NOT NULL
);

-- Inventory table (tracks stock quantity)
CREATE TABLE Inventory (
    InventoryID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT NOT NULL,
    StockQuantity INT NOT NULL DEFAULT 0,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Orders table
CREATE TABLE Orders (
    OrderID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL DEFAULT (CURRENT_DATE),
    TotalAmount DECIMAL(10, 2),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- OrderDetails table
CREATE TABLE OrderDetails (
    OrderDetailID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- VendorOrders table
CREATE TABLE VendorOrders (
    VendorOrderID INT AUTO_INCREMENT PRIMARY KEY,
    VendorID INT NOT NULL,
    OrderDate DATE NOT NULL DEFAULT (CURRENT_DATE),
    TotalAmount DECIMAL(10, 2),
    FOREIGN KEY (VendorID) REFERENCES Vendors(VendorID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- VendorOrderDetails table
CREATE TABLE VendorOrderDetails (
    VendorOrderDetailID INT AUTO_INCREMENT PRIMARY KEY,
    VendorOrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    Cost DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (VendorOrderID) REFERENCES VendorOrders(VendorOrderID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- SalesRecords table
CREATE TABLE SalesRecords (
    SalesRecordID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT NOT NULL,
    SaleDate DATE NOT NULL DEFAULT (CURRENT_DATE),
    Quantity INT NOT NULL,
    TotalRevenue DECIMAL(10, 2),
    CustomerID INT,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- Step 1: Create the ProductReceipts table to log products that arrive at the business premises
CREATE TABLE ProductReceipts (
    ReceiptID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT NOT NULL,
    VendorOrderID INT NOT NULL,
    ReceivedQuantity INT NOT NULL,
    ReceiptDate DATE NOT NULL DEFAULT (CURRENT_DATE),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (VendorOrderID) REFERENCES VendorOrders(VendorOrderID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Step 2: Update stock quantity of products when a product receipt is logged

DELIMITER $$

-- Trigger to update the inventory when products are received
CREATE TRIGGER UpdateInventoryOnReceipt
AFTER INSERT ON ProductReceipts
FOR EACH ROW
BEGIN
    -- Update Inventory stock quantity
    UPDATE Inventory
    SET StockQuantity = StockQuantity + NEW.ReceivedQuantity
    WHERE ProductID = NEW.ProductID;
    
    -- Ensure product entry exists in Inventory if not already present
    IF (SELECT COUNT(*) FROM Inventory WHERE ProductID = NEW.ProductID) = 0 THEN
        INSERT INTO Inventory (ProductID, StockQuantity)
        VALUES (NEW.ProductID, NEW.ReceivedQuantity);
    END IF;
END$$


-- Trigger to update stock on order
CREATE TRIGGER UpdateStockOnOrder
AFTER INSERT ON OrderDetails
FOR EACH ROW
BEGIN
    -- Update Inventory stock quantity
    UPDATE Inventory
    SET StockQuantity = StockQuantity - NEW.Quantity
    WHERE ProductID = NEW.ProductID;
END$$

-- Trigger for restocking if the stock quantity goes below the threshold
CREATE TRIGGER RestockNotification
AFTER UPDATE ON Inventory
FOR EACH ROW
BEGIN
    IF NEW.StockQuantity < (SELECT ReorderThreshold FROM Products WHERE ProductID = NEW.ProductID) THEN
        -- Create a new Vendor Order
        INSERT INTO VendorOrders (VendorID, TotalAmount) 
        VALUES (1, NEW.StockQuantity * (SELECT UnitPrice FROM Products WHERE ProductID = NEW.ProductID));
        
        -- Add product details to the Vendor Order
        INSERT INTO VendorOrderDetails (VendorOrderID, ProductID, Quantity, Cost)
        VALUES (LAST_INSERT_ID(), NEW.ProductID, 10, (SELECT UnitPrice FROM Products WHERE ProductID = NEW.ProductID) * 0.9);
        
        -- Update Inventory stock
        UPDATE Inventory 
        SET StockQuantity = StockQuantity + 10 
        WHERE ProductID = NEW.ProductID;
    END IF;
END$$


CREATE TRIGGER UpdateSalesRevenue
AFTER INSERT ON OrderDetails
FOR EACH ROW
BEGIN
    DECLARE revenue DECIMAL(10, 2);

    -- Calculate the revenue with 20% markup
    SET revenue = NEW.Quantity * NEW.Price * 1.20;

    -- Insert into SalesRecords
    INSERT INTO SalesRecords (ProductID, SaleDate, Quantity, TotalRevenue, CustomerID)
    SELECT NEW.ProductID, (SELECT OrderDate FROM Orders WHERE OrderID = NEW.OrderID), 
           NEW.Quantity, revenue, (SELECT CustomerID FROM Orders WHERE OrderID = NEW.OrderID);
END$$

DELIMITER ;


