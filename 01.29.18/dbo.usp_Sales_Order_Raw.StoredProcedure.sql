USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_Sales_Order_Raw]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_Sales_Order_Raw] 
AS

/* ==========================================================================
DESCRIPTION

	Proc Name:  usp_Sales_Order_Raw
	Purpose:    

	NOTES

	MODIFICATIONS

	Date	    Author		Purpose
	------------------------------------------------

	2017-06-05  Vitaly Romm	Initial version
	
	EXEC dbo.usp_Sales_Order_Raw

========================================================================== */  


--DECLARE @ContractID INT = 68159


IF OBJECT_ID('RevPro..Sales_Order_Raw') IS NOT NULL
    DROP TABLE RevPro..Sales_Order_Raw
    

SELECT DISTINCT --TOP 100 
	  STG_ID = IDENTITY (INT, 1,1),
      CAST('0083' AS VARCHAR(100)) AS CLIENT_ID,

	  CAST(CONVERT(VARCHAR(11), L.CurrentTermStartDate, 113) AS DATETIME)	AS Deal_ID_CurrentTermStartDate,
	  CAST(CONVERT(VARCHAR(11), L.CreatedDate, 113) AS DATETIME)			AS Deal_ID_CreatedDate,
	  CAST(C.LocationID AS VARCHAR(100)) AS Deal_ID_LocationID,

	  GL.CARVE_IN_DEF_REVENUE_SEG1,
	  SKUP.MarketName AS CARVE_IN_DEF_REVENUE_SEG2,	
	  GL.CARVE_IN_DEF_REVENUE_SEG3,
	  SKUP.ProductCategory AS CARVE_IN_DEF_REVENUE_SEG4, 

	  GL.UNBILLED_AR_SEG1,
	  SKUP.MarketName AS UNBILLED_AR_SEG2,		
	  GL.UNBILLED_AR_SEG3,
	  SKUP.ProductCategory AS UNBILLED_AR_SEG4,
		
	  GL.CARVE_IN_REVENUE_SEG1, 
	  SKUP.MarketName AS CARVE_IN_REVENUE_SEG2,	
	  GL.CARVE_IN_REVENUE_SEG3,
	  SKUP.ProductCategory AS CARVE_IN_REVENUE_SEG4, 	

	  GL.CARVE_OUT_REVENUE_SEG1, 
	  SKUP.MarketName	AS CARVE_OUT_REVENUE_SEG2,	
	  GL.CARVE_OUT_REVENUE_SEG3,
	  SKUP.ProductCategory AS CARVE_OUT_REVENUE_SEG4, 

	  ISNULL(CI.MajorAccountFlag,0) AS ATTRIBUTE24,
	  SKUP.MarketName AS ATTRIBUTE25,	 
	  'SAL' AS ATTRIBUTE26,
	  SKUP.ProductCategory AS ATTRIBUTE27,

	  MU.MonetaryUnitCode AS BASE_CURR_CODE,
	  'USA' AS BILL_TO_COUNTRY,

	  CASE L.LineItemInvoiceConfigurationID 
		WHEN 1 THEN BillLoc.LocationName
	           ELSE SiteLoc.LocationName 
	  END AS BILL_TO_CUSTOMER_NAME,

	  C.BillingLocationID AS BILL_TO_CUSTOMER_NUMBER,

	  CSB.CoStarBrandCode AS BUSINESS_UNIT,
	  L.SiteLocationID AS CUSTOMER_ID,

	  REPLACE(REPLACE(SiteLoc.LocationName,CHAR(13),''),CHAR(10),'') AS CUSTOMER_NAME, 

	  GL.DEF_ACCTG_SEG1,
	  SKUP.MarketName AS DEF_ACCTG_SEG2, 
	  GL.DEF_ACCTG_SEG3,
	  SKUP.ProductCategory AS DEF_ACCTG_SEG4, 

	  'Y' AS DEFERRED_REVENUE_FLAG,
	  0 AS DISCOUNT_AMOUNT,
	  0 AS DISCOUNT_PERCENT,	

	  L.CreatedDate AS ELIGIBLE_FOR_CV_CreateDated,
	  L.CreatedDate AS ELIGIBLE_FOR_FV_CreateDated,

      CAST(1 AS NUMERIC(2,1)) AS EX_RATE,
      CAST(0 AS NUMERIC (18, 4)) AS EXT_LIST_PRICE,
      CAST(0 AS NUMERIC (18, 4)) AS EXT_SELL_PRICE,
      'N' AS FLAG_97_2,

      '' AS INVOICE_DATE,
      '' AS INVOICE_ID,
      '' AS INVOICE_LINE,
      '' AS INVOICE_LINE_ID,
      '' AS INVOICE_NUMBER,
      '' AS INVOICE_TYPE,

	  P.ProductName AS ITEM_DESC,
	  P.ProductID AS ITEM_ID,

      ISNULL(SKUP.SKUID,999999999) AS ITEM_NUMBER,	

      '2282'	AS LT_DEFERRED_ACCOUNT,
      'N'		AS NON_CONTINGENT_FLAG,

      '' AS ORDER_LINE_TYPE,
      '' AS ORDER_TYPE,
      P.CoStarBrandID					AS ORG_ID,
      '' AS ORIG_INV_LINE_ID,

      'N'								AS PCS_FLAG,
      ''								AS PO_NUM,
      L.LineItemTypeID					AS PRODUCT_CATEGORY,
      ISNULL(P.ProductTypeID,0)			AS PRODUCT_CLASS,
	  ISNULL(P.ProductDesc,'CoStar')	AS PRODUCT_FAMILY,
	  P.ProductName						AS PRODUCT_LINE,

	  ''						AS QUANTITY_INVOICED,

	  L.CurrentTermStartDate	AS QUANTITY_ORDERED_SHIPPED_BillingStartDate,
	  L.RenewalDate				AS QUANTITY_ORDERED_SHIPPED_RenewalDate,

      'Y'						AS QUOTE_NUM,
      CAST(1 AS NUMERIC(2,1))	AS RCURR_EX_RATE,
      'N'						AS RETURN_FLAG,

      GL.REV_ACCTG_SEG1, 
	  SKUP.MarketName			AS REV_ACCTG_SEG2, 
      GL.REV_ACCTG_SEG3,
	  SKUP.ProductCategory		AS REV_ACCTG_SEG4,

	  L.RenewalDate				AS RULE_END_DATE,	
	  L.CurrentTermStartDate	AS RULE_START_DATE,

      L.ContractID AS SALES_ORDER,
      L.ContractID AS SALES_ORDER_ID,
      L.LineItemID AS SALES_ORDER_LINE,
      CAST(C.ContractID AS VARCHAR(10)) + SPACE(1) + CAST(ISNULL(SKUP.SKUID,999999999) AS VARCHAR(100)) + SPACE(1) + CAST(YEAR(L.CurrentTermStartDate) AS VARCHAR(10)) AS SALES_ORDER_LINE_ID,

      0 AS SALES_REP_ID,
      '' AS SALESREP_NAME,
      CAST(CONVERT(VARCHAR(11), L.BillingStartDate, 113) AS DATETIME) AS SCHEDULE_SHIP_DATE,
      'RIG' AS SEC_ATTR_VALUE,
      CAST(CONVERT(VARCHAR(11), L.BillingStartDate, 113) AS DATETIME) AS SHIP_DATE,
      CAST(CONVERT(VARCHAR(11), L.CreatedDate, 113) AS DATETIME) AS SO_BOOK_DATE,

	  L.LineItemID AS SOB_ID,
      'N' AS STANDALONE_FLAG,
      'N' AS STATED_FLAG,
      'SO' AS TRAN_TYPE,
      MU.MonetaryUnitCode AS TRANS_CURR_CODE,
      CAST(CONVERT(VARCHAR(11), L.CreatedDate, 113) AS DATETIME)  AS TRANS_DATE,	

      'Y' AS UNBILLED_ACCOUNTING_FLAG,
      'N' AS UNDELIVERED_FLAG,
	
	  CAST(L.DiscountedMonthlyPrice AS NUMERIC (18, 4)) AS UNIT_LIST_PRICE,						
	  CAST(L.DiscountedMonthlyPrice AS NUMERIC (18, 4)) AS UNIT_SELL_PRICE,	

      YEAR(L.CurrentTermStartDate) AS FV_YEAR,					

	  CASE WHEN Stub_Fl = 1
           THEN (ISNULL(CAST(L.DiscountedMonthlyPrice AS NUMERIC (18, 4)),0)/DAY(EOMONTH(L.CurrentTermStartDate))) * (DATEDIFF(DAY, L.CurrentTermStartDate, DATEADD(MONTH, 1, L.CurrentTermStartDate)) - DATEPART(DAY,L.CurrentTermStartDate) + 1)
		   ELSE 0 
	  END AS STUB_AMOUNT,										

      L.CreatedDate AS CONVERSION_DATA_CreatedDate,				
      1				AS CANCELLED_FLAG_LineItemStatusID,	

      GL.CARVE_IN_DEF_REVENUE_SEG5 AS CARVE_IN_DEF_REVENUE_SEG5, 
	  GL.UNBILLED_AR_SEG5			AS UNBILLED_AR_SEG5, 
	  GL.CARVE_IN_REVENUE_SEG5		AS CARVE_IN_REVENUE_SEG5, 
	  GL.CARVE_OUT_REVENUE_SEG5	AS CARVE_OUT_REVENUE_SEG5, 
	  GL.DEF_ACCTG_SEG5			AS DEF_ACCTG_SEG5, 
	  GL.REV_ACCTG_SEG5			AS REV_ACCTG_SEG5, 
	  GL.LT_DEFERRED_ACCOUNT_SEG5	AS LT_DEFERRED_ACCOUNT_SEG5,

      '0' AS ATTRIBUTE28,
	  '' AS NUMBER5,
	  ISNULL(L.BundleID,0) AS BundleID,
	  'N' AS DW_Fl,
	  'N' AS RPro_Fl,
	  'System' AS Created_By,
	  GETDATE() AS Create_Dt,
	  'System' AS Last_Updated_By,
	  GETDATE() AS Last_Update_Dt
INTO RevPro..Sales_Order_Raw
FROM RevPro..Active_LineItems L
	JOIN Staging..[Contract] C 
		ON L.Contractid = C.Contractid	
	JOIN Staging..Product P
		ON L.ProductID = P.ProductID
	JOIN RevPro..vwAllLocations SiteLoc  
		ON L.SiteLocationID = SiteLoc.LocationID
	JOIN RevPro..vwAllLocations BillLoc 
		ON C.BillingLocationID = BillLoc.LocationID
	JOIN Staging..MonetaryUnit MU
		ON L.MonetaryUnitID = MU.MonetaryUnitID
	JOIN Staging..CoStarBrand CSB
		ON P.CoStarBrandID = CSB.CoStarBrandID
	JOIN Staging..CoStarSubsidiary CSS
		ON CSB.CoStarSubsidiaryID = CSS.CoStarSubsidiaryID
		AND CSS.CostarSubsidiaryName = 'CoStar Group HQ'
	LEFT JOIN Staging..CustomerInfo CI
		ON L.SiteLocationID = CI.locationid 
		  AND CSB.CoStarSubsidiaryID = CI.CoStarSubsidiaryID
	JOIN Staging..RevPro_GL_Mapping GL
		ON L.ProductID = GL.ProductID
		AND GL.Active_Fl = 1
	JOIN RevPro..SkuBridge SKUB
		ON L.LineItemID = SKUB.LineItemID
	JOIN RevPro..SkuPrice SKUP
		ON SKUB.SkUID = SKUP.SkuID
WHERE L.BillingStartDate IS NOT NULL
AND L.CurrentTermStartDate IS NOT NULL
AND L.RenewalDate IS NOT NULL
--




GO
