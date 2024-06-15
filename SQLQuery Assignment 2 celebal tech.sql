--SRUTI PRAKASH BEHERA

----Create a procedure InsertOrderDetails that takes OrderID, ProductID, UnitPrice, Quantiy, Discount as input parameters and inserts that order information 
--in the Order Details table. After each order inserted, check the @@rowcount value to make sure that order was inserted properly. 
--If for any reason the order was not inserted, print the message: Failed to place the order. Please try again. Also your procedure should have these functionalities
----Make the UnitPrice and Discount parameters optional
----If no UnitPrice is given, then use the UnitPrice value from the product table.
----If no Discount is given, then use a discount of 0...
----Adjust the quantity in stock (UnitsInStock) for the product by subtracting the quantity sold from inventory.
----However, if there is not enough of a product in stock, then abort the stored procedure without making any changes to the database.
----Print a message if the quantity in stock of a product drops below its Reorder Level as a result of the update.
USE AdventureWorks2019;
GO
IF OBJECT_ID('InsertOrderDetails', 'P') IS NOT NULL
    DROP PROCEDURE InsertOrderDetails;
GO
CREATE PROCEDURE InsertOrderDetails
    @SalesOrderID int,
    @ProductID int,
    @OrderQty int,
    @UnitPrice money = NULL,
    @UnitPriceDiscount float = 0,
    @SpecialOfferID int  -- Add this line
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UnitsInStock int, @ReorderPoint int, @ListPrice money;

    SELECT @UnitsInStock = ProductInventory.Quantity, @ReorderPoint = Product.ReorderPoint, @ListPrice = Product.ListPrice
    FROM Production.Product
    INNER JOIN Production.ProductInventory ON Product.ProductID = ProductInventory.ProductID
    WHERE Product.ProductID = @ProductID;

    IF @UnitsInStock < @OrderQty
    BEGIN
        PRINT 'There is not enough of a product in stock.';
        RETURN;
    END

    IF @UnitPrice IS NULL
    BEGIN
        SET @UnitPrice = @ListPrice;
    END

    INSERT INTO Sales.SalesOrderDetail(SalesOrderID, OrderQty, ProductID, UnitPrice, UnitPriceDiscount, SpecialOfferID)
    VALUES (@SalesOrderID, @OrderQty, @ProductID, @UnitPrice, @UnitPriceDiscount, @SpecialOfferID);

    IF @@ROWCOUNT = 0
    BEGIN
        PRINT 'Failed to place the order. Please try again.';
        RETURN;
    END

    UPDATE Production.ProductInventory
    SET Quantity = Quantity - @OrderQty
    WHERE ProductID = @ProductID;

    IF (@UnitsInStock - @OrderQty) < @ReorderPoint
    BEGIN
        PRINT 'The quantity in stock of a product drops below its Reorder Level as a result of the update.';
    END
END
GO
-- Assuming we have the following sample data
DECLARE @SampleSalesOrderID int;
SET @SampleSalesOrderID = 1;
DECLARE @SampleProductID int;
SET @SampleProductID = 1;
DECLARE @SampleOrderQty int;
SET @SampleOrderQty = 10;
DECLARE @SpecialOfferID int;
SET @SpecialOfferID = 11;

-- Check if the SalesOrderID exists in the Sales.SalesOrderHeader table
IF EXISTS (SELECT 1 FROM Sales.SalesOrderHeader WHERE SalesOrderID = @SampleSalesOrderID)
BEGIN
    -- Call the stored procedure with the sample data
    EXEC InsertOrderDetails @SalesOrderID = @SampleSalesOrderID, @ProductID = @SampleProductID, @OrderQty = @SampleOrderQty, @SpecialOfferID = @SpecialOfferID;
END
ELSE
BEGIN
    PRINT 'The SalesOrderID does not exist in the Sales.SalesOrderHeader table.';
END

----Create a procedure UpdateOrderDetails that takes OrderID, ProductID, UnitPrice, Quantity, and discount, and updates these values for that ProductID in that Order.
----All the parameters except the OrderID and ProductID should be optional so that if the user wants to only update Quantity s/he should be able to do so without 
--providing the rest of the values. You need to also make sure that if any of the values are being passed in as NULL, then you want to retain the original 
--value instead of overwriting it with NULL. To accomplish this, look for the ISNULL() function in google or sql server books online. 
--Adjust the UnitsInStock value in products table accordingly.
CREATE PROCEDURE UpdateOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice DECIMAL(18, 2) = NULL,
    @Quantity INT = NULL,
    @Discount DECIMAL(4, 2) = NULL
AS
BEGIN
   
    DECLARE @OriginalUnitPrice DECIMAL(18, 2);
    DECLARE @OriginalQuantity INT;
    DECLARE @OriginalDiscount DECIMAL(4, 2);
    DECLARE @LocationID INT;

   
    SELECT 
        @OriginalUnitPrice = UnitPrice,
        @OriginalQuantity = OrderQty,
        @OriginalDiscount = UnitPriceDiscount
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

   
    DECLARE @QuantityDifference INT;
    SET @QuantityDifference = ISNULL(@Quantity, @OriginalQuantity) - @OriginalQuantity;

   
    UPDATE Sales.SalesOrderDetail
    SET
        UnitPrice = ISNULL(@UnitPrice, UnitPrice),
        OrderQty = ISNULL(@Quantity, OrderQty),
        UnitPriceDiscount = ISNULL(@Discount, UnitPriceDiscount)
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

   
    SELECT @LocationID = LocationID
    FROM Production.ProductInventory
    WHERE ProductID = @ProductID;

    
    UPDATE Production.ProductInventory
    SET Quantity = Quantity - @QuantityDifference
    WHERE ProductID = @ProductID AND LocationID = @LocationID;
END;

----Create a procedure GetOrderDetails that takes OrderID as input parameter and returns all the records for that OrderID. 
----If no records are found in Order Details table, then it should print the line: "The OrderID XXXX does not exits", where XXX should be the OrderID entered by user and 
------the procedure should RETURN the value 1.
CREATE PROCEDURE GetOrderDetails
    @OrderID INT
AS
BEGIN
    DECLARE @RecordCount INT;

    SELECT @RecordCount = COUNT(*)
    FROM OrderDetails
    WHERE OrderID = @OrderID;
    IF @RecordCount = 0
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR) + ' does not exist';
        RETURN 1;
    END

    SELECT *
    FROM OrderDetails
    WHERE OrderID = @OrderID;
END;
GO

--Create a procedure DeleteOrderDetails that takes OrderID and ProductID and deletes that from Order Details table.
--Your procedure should validate parameters. It should return an error code (-1) and print a message if the parameters are invalid.
--Parameters are valid if the given order ID appears in the table and if the given product ID appears in that order.
( @InputDate DATETIME ) 
RETURNS VARCHAR(10) AS BEGIN RETURN (RIGHT('0' + CAST(MONTH(@InputDate) 
AS VARCHAR(2)), 2) + '/' + RIGHT('0' + CAST(DAY(@InputDate) AS VARCHAR(2)), 2) + '/' + CAST(YEAR(@InputDate) AS VARCHAR(4))); 
END;

--Create a function that takes an input parameter type datetime and returns the date in the format MM/DD/YYYY. For example if I pass in '2006-11-21 23:34:05.920',
--the output of the functions should be 11/21/2006
--Create a function that takes an input parameter type datetime and returns the date in the format YYYYMMDD
( @InputDate DATETIME ) 
RETURNS VARCHAR(8)
 AS BEGIN RETURN (CAST(YEAR(@InputDate) AS VARCHAR(4)) + RIGHT('0' + CAST(MONTH(@InputDate) AS VARCHAR(2)), 2) + RIGHT('0' + CAST(DAY(@InputDate) AS VARCHAR(2)), 2)); 
END;
Create a view vwCustomerOrders which returns CompanyName, OrderID, OrderDate, ProductID,Product Name, Quantity, UnitPrice, Quantity* od. UnitPrice

Create a copy of the above view and modify it so that it only returns the above information for orders that were placed yesterday

--Use a CREATE VIEW statement to create a view called MyProducts. Your view should contain the ProductID, ProductName, QuantityPerUnit and UnitPrice 
--columns from the Products table. It should also contain the CompanyName column from the Suppliers table and the CategoryName column from the Categories table.
--Your view should only contain products that are not discontinued.
CREATE VIEW vwCustomerOrders AS SELECT c.CompanyName, o.OrderID, o.OrderDate, pp.ProductID, pp.Name, od.Quantity, od.UnitPrice, 
od.Quantity * od.UnitPrice AS TotalPrice FROM Sales.Customers c INNER JOIN Orders o ON c.CustomerID = o.CustomerID 
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID INNER JOIN Production.products p ON od.ProductID = pp.ProductID;

--If someone cancels an order in northwind database, then you want to delete that order from the Orders table. 
--But you will not be able to delete that Order before deleting the records from Order Details table for that particular order due to referential integrity constraints. 
--Create an Instead of Delete trigger on Orders table so that if some one tries to delete an Order that trigger gets fired and that trigger should 
--first delete everything, in order details table and then delete that order from the Orders table

CREATE VIEW vwCustomerOrders AS SELECT c.CompanyName, o.OrderID, o.OrderDate, pp.ProductID, pp.Name, od.Quantity, od.UnitPrice, od.Quantity * od.UnitPrice AS 
TotalPrice FROM Sales.Customers c INNER JOIN Orders o ON c.CustomerID = o.CustomerID INNER JOIN OrderDetails od 
ON o.OrderID = od.OrderID INNER JOIN Production.products p ON od.ProductID = pp.ProductID;
WHERE o.OrderDate >= CAST(DATEADD(DAY, -1, GETDATE()) AS DATE) AND o.OrderDate < CAST(GETDATE() AS DATE);

--When an order is placed for X units of product Y, we must first check the Products table to ensure that there is sufficient stock to fill the order. 
--This trigger will operate on the Order Details table. If sufficient stock exists, then fill the order and decrement X units from the UnitsInStock column in Products.
--If insufficient stock exists, then refuse the order (ie, do not insert it) and notify the user that the order could not be filled because of insufficient stock.
CREATE VIEW MyProducts  AS SELECT pp.ProductID, pp.Name, pp.QuantityPerUnit, pp.UnitPrice, s.CompanyName, c.CategoryName FROM
Production.Products pp INNER JOIN Suppliers s ON pp.SupplierID = s.SupplierID INNER JOIN Categories c ON pp.CategoryID = c.CategoryID
INNER JOIN  
WHERE p.Discontinued = 0;