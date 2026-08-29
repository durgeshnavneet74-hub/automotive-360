-- =============================================================================
-- AUTOMOTIVE DATA ANALYTICS & ETL PROJECT: END-TO-END SQL SCRIPT
-- Database: MS SQL Server (SSMS) / T-SQL compatible
-- =============================================================================


-- -----------------------------------------------------------------------------
-- STEP 1: DATABASE INITIALIZATION
-- -----------------------------------------------------------------------------
-- Create the database instance
CREATE DATABASE car;
GO

-- Switch context to the newly created database
USE car;
GO


-- -----------------------------------------------------------------------------
-- STEP 2: STAGING DDL DEFINITIONS (5 FLAT FILE TABLES)
-- -----------------------------------------------------------------------------
-- Note: When using the SSMS "Import Flat File" wizard, tables are auto-generated.
-- If creating tables manually before bulk ingestion, execute the DDL below:

-- 1. Car Master Entity
IF OBJECT_ID('dbo.Car', 'U') IS NOT NULL DROP TABLE dbo.Car;
CREATE TABLE Car (
    Car_ID VARCHAR(50) PRIMARY KEY,
    Brand VARCHAR(100),
    Model VARCHAR(100),
    Year INT,
    Fuel_Type VARCHAR(50),
    Transmission VARCHAR(50),
    Color VARCHAR(50),
    Owner_Type VARCHAR(50),
    Mileage_kmpl DECIMAL(10, 2),
    Price_Lakh DECIMAL(10, 2)
);
GO

-- 2. Insurance Entity
IF OBJECT_ID('dbo.Insurance', 'U') IS NOT NULL DROP TABLE dbo.Insurance;
CREATE TABLE Insurance (
    Car_ID VARCHAR(50),
    Provider VARCHAR(100),
    Policy_Number VARCHAR(100),
    Expiry_Date DATE,
    Status VARCHAR(50)
);
GO

-- 3. Owners Entity
IF OBJECT_ID('dbo.Owners', 'U') IS NOT NULL DROP TABLE dbo.Owners;
CREATE TABLE Owners (
    Car_ID VARCHAR(50),
    Owner_Name VARCHAR(100),
    Contact VARCHAR(50),
    City VARCHAR(100),
    Purchase_Year INT
);
GO

-- 4. Sales Entity
IF OBJECT_ID('dbo.Sales', 'U') IS NOT NULL DROP TABLE dbo.Sales;
CREATE TABLE Sales (
    Car_ID VARCHAR(50),
    Sale_Price_Lakh DECIMAL(10, 2),
    Sale_Date DATE,
    Buyer_Name VARCHAR(100)
);
GO

-- 5. Service History Entity
IF OBJECT_ID('dbo.Service_History', 'U') IS NOT NULL DROP TABLE dbo.Service_History;
CREATE TABLE Service_History (
    Car_ID VARCHAR(50),
    Service_Type VARCHAR(100),
    Service_Date DATE,
    Service_Cost DECIMAL(10, 2),
    Service_Center VARCHAR(100)
);
GO


-- -----------------------------------------------------------------------------
-- STEP 3: STAGING VERIFICATION QUERIES
-- -----------------------------------------------------------------------------
-- Verify that all 5 flat files imported correctly with their records intact
SELECT TOP 1000 * FROM Car;
SELECT TOP 1000 * FROM Insurance;
SELECT TOP 1000 * FROM Owners;
SELECT TOP 1000 * FROM Sales;
SELECT TOP 1000 * FROM Service_History;
GO


-- -----------------------------------------------------------------------------
-- STEP 4: MASTER TABLE TRANSFORMATION & CONSOLIDATION (ETL PIPELINE)
-- -----------------------------------------------------------------------------
-- Remove existing consolidated table if previously generated
IF OBJECT_ID('dbo.master_car_data', 'U') IS NOT NULL 
    DROP TABLE dbo.master_car_data;
GO

-- Consolidate records from all 5 entities via LEFT JOIN into master_car_data
SELECT 
    c.Car_ID,
    c.Brand,
    c.Model,
    c.Year,
    c.Fuel_Type,
    c.Transmission,
    c.Color,
    c.Owner_Type,
    c.Mileage_kmpl,
    c.Price_Lakh,
    i.Provider AS Insurance_Provider,
    i.Policy_Number,
    i.Expiry_Date AS Insurance_Expiry_Date,
    i.Status AS Insurance_Status,
    o.Owner_Name,
    o.Contact AS Owner_Contact,
    o.City,
    o.Purchase_Year,
    s.Sale_Price_Lakh,
    s.Sale_Date,
    s.Buyer_Name,
    sh.Service_Type,
    sh.Service_Date,
    sh.Service_Cost,
    sh.Service_Center
INTO master_car_data
FROM Car c
LEFT JOIN Insurance i 
    ON c.Car_ID = i.Car_ID
LEFT JOIN Owners o 
    ON c.Car_ID = o.Car_ID
LEFT JOIN Sales s 
    ON c.Car_ID = s.Car_ID
LEFT JOIN Service_History sh 
    ON c.Car_ID = sh.Car_ID;
GO

-- Verify generated master table
SELECT TOP 1000 * FROM master_car_data;
GO


-- -----------------------------------------------------------------------------
-- STEP 5: VALIDATION & DASHBOARD ANALYTICS QUERIES
-- -----------------------------------------------------------------------------

-- 1. Total Record & Unique Vehicle Verification
SELECT 
    COUNT(*) AS Total_Master_Records,
    COUNT(DISTINCT Car_ID) AS Total_Unique_Cars
FROM master_car_data;

-- 2. Top Summary KPI Cards (Matching Power BI Header Cards)
SELECT 
    COUNT(DISTINCT Car_ID) AS Total_Cars,
    ROUND(SUM(Sale_Price_Lakh), 2) AS Total_Sales_In_Lakhs,
    COUNT(DISTINCT Brand) AS Total_Brands,
    COUNT(DISTINCT Fuel_Type) AS Total_Fuel_Types,
    COUNT(DISTINCT Model) AS Total_Models
FROM master_car_data;

-- 3. Vehicle Inventory by Fuel Type (Horizontal Bar Chart Visual)
SELECT 
    Fuel_Type, 
    COUNT(DISTINCT Car_ID) AS Total_Cars
FROM master_car_data
GROUP BY Fuel_Type
ORDER BY Total_Cars DESC;

-- 4. Annual Sales Trends (Vertical Column Chart Visual)
SELECT 
    YEAR(Sale_Date) AS Sales_Year,
    ROUND(SUM(Sale_Price_Lakh), 2) AS Total_Sales_Lakh,
    COUNT(DISTINCT Car_ID) AS Cars_Sold
FROM master_car_data
WHERE Sale_Date IS NOT NULL
GROUP BY YEAR(Sale_Date)
ORDER BY Sales_Year ASC;

-- 5. Cars by Model Distribution (Donut Chart Visual)
SELECT 
    Model,
    COUNT(DISTINCT Car_ID) AS Total_Cars,
    ROUND(COUNT(DISTINCT Car_ID) * 100.0 / (SELECT COUNT(DISTINCT Car_ID) FROM master_car_data), 2) AS Percentage_Share
FROM master_car_data
GROUP BY Model
ORDER BY Total_Cars DESC;

-- 6. Transmission Mix: Manual vs Automatic (Pie Chart Visual)
SELECT 
    Transmission,
    COUNT(DISTINCT Car_ID) AS Total_Cars,
    ROUND(COUNT(DISTINCT Car_ID) * 100.0 / (SELECT COUNT(DISTINCT Car_ID) FROM master_car_data), 2) AS Percentage_Share
FROM master_car_data
GROUP BY Transmission;

-- 7. After-Sales Service Cost Analysis by Service Type
SELECT 
    Service_Type,
    COUNT(*) AS Total_Services_Logged,
    ROUND(AVG(Service_Cost), 2) AS Avg_Service_Cost_INR,
    ROUND(SUM(Service_Cost), 2) AS Total_Service_Revenue_INR
FROM master_car_data
WHERE Service_Type IS NOT NULL
GROUP BY Service_Type
ORDER BY Total_Service_Revenue_INR DESC;

-- 8. Insurance Status & Expiry Risk Analysis
SELECT 
    Insurance_Provider,
    Insurance_Status,
    COUNT(DISTINCT Car_ID) AS Total_Policies
FROM master_car_data
WHERE Insurance_Provider IS NOT NULL
GROUP BY Insurance_Provider, Insurance_Status
ORDER BY Insurance_Provider, Total_Policies DESC;
GO
