USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_SKU_LoadLineItem]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_SKU_LoadLineItem]
AS

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LineItem]'))
BEGIN DROP TABLE dbo.LineItem  END;

SELECT 
LI.LineItemID as LineItemID, 
LI.ContractID as ContractID,
COALESCE(BundleID,[dbo].[fnGetMaxBundle](LI.ContractID)) as BundleID,
ISNULL(ProductID,-1) as ProductID,
ISNULL(ProductMarket,'-1') as MarketID,
ISNULL(NumberOfUsers,0) as UserCount,
ISNULL(BTC.BusinessTypeCategoryID,8) as CustomerType, 
LI.BillingStartDate as [Date], 
-1 as SKUID ,
CAST (DiscountedMonthlyPrice AS decimal(10,2)) as DiscountedMonthlyPrice,
CAST (OriginalMonthlyPrice AS decimal(10,2)) as OriginalMonthlyPrice,
CAST (CurrentMonthlyPrice AS decimal(10,2)) as Amount
INTO dbo.LineItem
FROM Staging..LineItem LI 
LEFT JOIN Staging.dbo.SalesUnitProductMarket SUPM on LI.SalesUnitID=SUPM.SalesUnitID LEFT JOIN
Staging..LocationProfile  LP ON LI.SiteLocationID=LP.LocationID LEFT JOIN
[dbo].[BusinessType] BT ON LP.BusinessTypeID=BT.BusinessTypeID LEFT JOIN [dbo].[BusinessTypeCategory] BTC ON
BT.BusinessTypeCategoryID=BTC.BusinessTypeCategoryID
WHERE LI.ContractID IN (SELECT ContractID from  [dbo].[Contract_Input_List]) 


GO
