-- DIM_CATEGORY: Product/service categories
CREATE TABLE dim_category (
    CategoryKey INT PRIMARY KEY,
    CategoryID VARCHAR(20) UNIQUE NOT NULL,
    CategoryName VARCHAR(50) NOT NULL,
    CategoryType VARCHAR(100) NOT NULL,
    CreatedDate TIMESTAMP ,
    UpdatedDate DATETIME
)

INSERT INTO dim_category (CategoryKey, CategoryID, CategoryName, CategoryType) VALUES
(1, 'Category_1', 'Category 1', 'Direct'),
(2, 'Category_2', 'Category 2', 'Emergency'),
(3, 'Category_3', 'Category 3', 'RFQ'),
(4, 'Category_4', 'Category 4', 'RFP'),
(5, 'Category_5', 'Category 5', 'Small Value Procurement'),
(6, 'Category_6', 'Category 6', 'Open Advertised Bidding'),
(7, 'Category_7', 'Category 7', 'Restricted Bidding'),
(8, 'Category_8', 'Category 8', 'Execution by public entities')

-- DIM_SUPPLIER: Supplier master data
CREATE TABLE dim_supplier (
    SupplierKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    SupplierID VARCHAR(20) UNIQUE NOT NULL,
    SupplierName VARCHAR(100) NOT NULL,
    Region VARCHAR(50),
    SupplierRiskScore DECIMAL(3,2),
    SupplierQualityRating INT,
    OnTimeDeliveryRate DECIMAL(5,2),
    SupplierAuditScore INT,
    SupplierDiversity BIT,
    CreatedDate TIMESTAMP,
    UpdatedDate DATETIME
)

INSERT INTO dim_supplier ( SupplierID, SupplierName, Region, SupplierRiskScore, SupplierQualityRating, OnTimeDeliveryRate, SupplierAuditScore, SupplierDiversity) 
SELECT  [SupplierID]
      ,[SupplierName]
      ,[Region]
      ,[SupplierRiskScore]
      ,[SupplierQualityRating]
      ,[OnTimeDeliveryRate]
      ,[SupplierAuditScore]
      ,[SupplierDiversity]
  FROM [ODS].[dbo].[suppliers]

  CREATE TABLE dim_contract (
    ContractKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ContractID VARCHAR(20) UNIQUE NOT NULL,
    SupplierKey INT NOT NULL,
    ContractStart DATE NOT NULL,
    ContractEnd DATE NOT NULL,
    ContractValue DECIMAL(15,2) NOT NULL,
    Renewed BIT NOT NULL,
    ContractCycleTimeDays INT,
    CreatedDate DATETIME,
    UpdatedDate DATETIME
    FOREIGN KEY (SupplierKey) REFERENCES dim_supplier(SupplierKey)
)

INSERT INTO dim_contract ( ContractID, SupplierKey, ContractStart, ContractEnd, ContractValue, Renewed, ContractCycleTimeDays) 
SELECT  a.[ContractID]
      ,b.[SupplierKey]
      ,a.[ContractStart]
      ,a.[ContractEnd]
      ,a.[ContractValue]
      ,a.[Renewed]
      ,a.[ContractCycleTimeDays]
  FROM [ODS].[dbo].[contracts] AS a
  JOIN [EDW].[dbo].[dim_supplier] AS b
    on a.[SupplierID] = b.[SupplierID]


CREATE TABLE dim_item (
    ItemKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ItemID VARCHAR(20) UNIQUE NOT NULL,
    CategoryKey INT NOT NULL,
    InventoryTurnover DECIMAL(5,2),
    StockOutRate DECIMAL(6,4),
    DemandForecastAccuracy DECIMAL(3,2),
    CreatedDate DATETIME,
    UpdatedDate DATETIME,
    FOREIGN KEY (CategoryKey) REFERENCES dim_category(CategoryKey)
)

INSERT INTO dim_item (ItemID, CategoryKey, InventoryTurnover, StockOutRate, DemandForecastAccuracy) 

SELECT  a.[ItemID]
      ,b.[CategoryKey]
      ,a.[InventoryTurnover]
      ,a.[StockOutRate]
      ,a.[DemandForecastAccuracy]
  FROM [ODS].[dbo].[inventory] AS a
  JOIN [EDW].[dbo].[dim_category] AS b
    on a.Category = b.CategoryID

-- FACT_PURCHASE_ORDER: Main transactional fact table
CREATE TABLE fact_purchase_order (
    POKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    POID VARCHAR(100) UNIQUE NOT NULL,
    SupplierKey INT NOT NULL,
    CategoryKey INT NOT NULL,
    PODate DATETIME NOT NULL,
    ApprovalDate DATETIME NOT NULL,
    POAmount DECIMAL(38,2) NOT NULL,
    InvoiceAmount DECIMAL(38,2) NOT NULL,
    POVariance DECIMAL(38,2) NOT NULL,
    POComplianceFlag BIT NOT NULL,
    POCycleTimeDays INT NOT NULL,
    CreatedDate DATETIME,
    FOREIGN KEY (SupplierKey) REFERENCES dim_supplier(SupplierKey),
    FOREIGN KEY (CategoryKey) REFERENCES dim_category(CategoryKey),
    INDEX idx_supplier (SupplierKey),
    INDEX idx_category (CategoryKey)
)

INSERT INTO fact_purchase_order (POID, SupplierKey, CategoryKey, PODate, ApprovalDate, POAmount, InvoiceAmount, POVariance, POComplianceFlag, POCycleTimeDays) 
SELECT [POID]
      ,b.SupplierKey
      ,c.CategoryKey
      ,[PODate]
      ,[ApprovalDate]
      ,[POAmount]
      ,[InvoiceAmount]
      ,[InvoiceAmount] - [POAmount]
      ,[POCompliance]
      ,[POCycleTimeDays]
  FROM [ODS].[dbo].[purchase_orders] AS a
  JOIN [EDW].[dbo].[dim_supplier] AS b
    ON a.SupplierID = b.SupplierID
  JOIN [EDW].[dbo].[dim_category] AS c
    ON a.Category = c.CategoryID


CREATE TABLE fact_spend_summary (
    SpendKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Month VARCHAR(7) NOT NULL,
    CategoryKey INT NOT NULL,
    TotalSpend DECIMAL(15,2) NOT NULL,
    Budget DECIMAL(15,2) NOT NULL,
    CostSavings DECIMAL(15,2) NOT NULL,
    SpendVariance DECIMAL(15,2) NOT NULL,
    CreatedDate DATETIME,
    FOREIGN KEY (CategoryKey) REFERENCES dim_category(CategoryKey),
    INDEX idx_category (CategoryKey)
)

INSERT INTO fact_spend_summary (Month, CategoryKey, TotalSpend, Budget, CostSavings, SpendVariance) 
SELECT [Month]
      ,b.[CategoryKey]
      ,[TotalSpend]
      ,[Budget]
      ,[CostSavings]
      ,[Budget] - [TotalSpend]
  FROM [ODS].[dbo].[spend_summary] AS a
  JOIN [EDW].[dbo].[dim_category] AS b
    on a.Category = b.CategoryID


--CREATE TABLE fact_contract_performance (
--    PerformanceKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
--    ContractKey INT NOT NULL,
--    SupplierKey INT NOT NULL,
--    PerformanceMonth VARCHAR(7) NOT NULL,
--    ContractUtilization DECIMAL(3,2) NOT NULL,
--    SLACompliance DECIMAL(3,2) NOT NULL,
--    CostPerformance DECIMAL(3,2) NOT NULL,
--    QualityScore INT NOT NULL,
--    CreatedDate DATETIME,
--    FOREIGN KEY (ContractKey) REFERENCES dim_contract(ContractKey),
--    FOREIGN KEY (SupplierKey) REFERENCES dim_supplier(SupplierKey),
--    INDEX idx_contract (ContractKey),
--    INDEX idx_supplier (SupplierKey),
--    INDEX idx_performance_month (PerformanceMonth)
--)

---INSERT INTO fact_contract_performance (ContractKey, SupplierKey, PerformanceMonth, ContractUtilization, SLACompliance, CostPerformance, QualityScore) 

