USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_Invoice_Raw]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_Invoice_Raw] 
AS

/* ==========================================================================
DESCRIPTION

	Proc Name:  usp_Invoice_Raw
	Purpose:    

	NOTES

	MODIFICATIONS

	Date	    Author		Purpose
	------------------------------------------------

	2017-06-05  Vitaly Romm	Initial version
	
	EXEC dbo.usp_Invoice_Raw

========================================================================== */  


--DECLARE @ContractID INT = 68159


IF OBJECT_ID('RevPro..Invoice_Raw') IS NOT NULL
    TRUNCATE TABLE RevPro..Invoice_Raw

-------------------------------------

DECLARE @MAX_Count		INT = (SELECT COUNT(*) FROM RevPro..CurrentTerm_Invoices),
        @Begin_Count	INT = 1,
		@End_Count		INT = 1000,
		@Increment		INT = 1000

--------------------------------------
 
WHILE @Begin_Count <= @MAX_Count
	BEGIN


INSERT INTO RevPro..Invoice_Raw
SELECT DISTINCT --TOP 100 
      CAST('0083' AS VARCHAR(100)) AS CLIENT_ID,

	  CAST(CONVERT(VARCHAR(11), SIL.CurrentTermStartDate, 113) AS DATETIME)	AS Deal_ID_CurrentTermStartDate,
	  CAST(CONVERT(VARCHAR(11), SIL.CreatedDate, 113) AS DATETIME)			AS Deal_ID_CreatedDate,
	  C.LocationID AS Deal_ID_LocationID,

	  GL.CARVE_IN_DEF_REVENUE_SEG1	AS CARVE_IN_DEF_REVENUE_SEG1,
	  SKUP.MarketName				AS CARVE_IN_DEF_REVENUE_SEG2,	
	  GL.CARVE_IN_DEF_REVENUE_SEG3	AS CARVE_IN_DEF_REVENUE_SEG3,
	  SKUP.ProductCategory			AS CARVE_IN_DEF_REVENUE_SEG4, 

	  GL.UNBILLED_AR_SEG1			AS UNBILLED_AR_SEG1,
	  SKUP.MarketName				AS UNBILLED_AR_SEG2,		
	  GL.UNBILLED_AR_SEG3			AS UNBILLED_AR_SEG3,
	  SKUP.ProductCategory			AS UNBILLED_AR_SEG4,
		
	  GL.CARVE_IN_REVENUE_SEG1		AS CARVE_IN_REVENUE_SEG1, 
	  SKUP.MarketName				AS CARVE_IN_REVENUE_SEG2,	
	  GL.CARVE_IN_REVENUE_SEG3		AS CARVE_IN_REVENUE_SEG3,
	  SKUP.ProductCategory			AS CARVE_IN_REVENUE_SEG4, 	

	  GL.CARVE_OUT_REVENUE_SEG1		AS CARVE_OUT_REVENUE_SEG1, 
	  SKUP.MarketName				AS CARVE_OUT_REVENUE_SEG2,	
	  GL.CARVE_OUT_REVENUE_SEG3		AS CARVE_OUT_REVENUE_SEG3,
	  SKUP.ProductCategory			AS CARVE_OUT_REVENUE_SEG4, 

	  ISNULL(CI.MajorAccountFlag,0) AS ATTRIBUTE24,
	  SKUP.MarketName				AS ATTRIBUTE25,	 
	  'SAL'							AS ATTRIBUTE26,
	  SKUP.ProductCategory			AS ATTRIBUTE27,

	  MU.MonetaryUnitCode			AS BASE_CURR_CODE,
	  'USA'							AS BILL_TO_COUNTRY,

	  CASE SIL.LineItemInvoiceConfigurationID 
		WHEN 1 THEN BillLoc.LocationName
	           ELSE SiteLoc.LocationName 
	  END							AS BILL_TO_CUSTOMER_NAME,

	  C.BillingLocationID			AS BILL_TO_CUSTOMER_NUMBER,

	  CSB.CoStarBrandCode			AS BUSINESS_UNIT,
	  SIL.SiteLocationID				AS CUSTOMER_ID,

	  REPLACE(REPLACE(SiteLoc.LocationName,CHAR(13),''),CHAR(10),'') AS CUSTOMER_NAME,

	  GL.DEF_ACCTG_SEG1				AS DEF_ACCTG_SEG1,
	  SKUP.MarketName				AS DEF_ACCTG_SEG2, 
	  GL.DEF_ACCTG_SEG3				AS DEF_ACCTG_SEG3,
	  SKUP.ProductCategory			AS DEF_ACCTG_SEG4, 

	  'Y'							AS DEFERRED_REVENUE_FLAG,

	  0								AS DISCOUNT_AMOUNT,	
	  0								AS DISCOUNT_PERCENT,

	  SIL.CreatedDate					AS ELIGIBLE_FOR_CV_CreateDated,
	  SIL.CreatedDate					AS ELIGIBLE_FOR_FV_CreateDated,

      CAST(1 AS NUMERIC(2,1))		AS EX_RATE,

      SIL.Amount					AS EXT_LIST_PRICE,
      SIL.Amount					AS EXT_SELL_PRICE,

      'N'							AS FLAG_97_2,

      CASE WHEN SIL.[Posting Date] < '1/1/1990' THEN SIL.[Shipment Date] ELSE SIL.[Posting Date] END	AS INVOICE_DATE,
      SIL.[Document No_]																				AS INVOICE_ID,
      SIL.[Line No_]																					AS INVOICE_LINE,
      CAST(SIL.[Document No_] AS VARCHAR(10)) + '-' + CAST(SIL.[Line No_] AS VARCHAR(10))				AS INVOICE_LINE_ID,
      SIL.[Document No_]																				AS INVOICE_NUMBER,
      'Invoice'																							AS INVOICE_TYPE,

	  P.ProductName					AS ITEM_DESC,
	  P.ProductID					AS ITEM_ID,

      ISNULL(SKUP.SKUID,'999999')	AS ITEM_NUMBER,

      '2282'						AS LT_DEFERRED_ACCOUNT,
      'N'							AS NON_CONTINGENT_FLAG,

      ''							AS ORDER_LINE_TYPE,
      ''							AS ORDER_TYPE,
      P.CoStarBrandID				AS ORG_ID,
      ''							AS ORIG_INV_LINE_ID,

      'N'								AS PCS_FLAG,
      ''								AS PO_NUM,
      SIL.LineItemTypeID				AS PRODUCT_CATEGORY,
      ISNULL(P.ProductTypeID,0)			AS PRODUCT_CLASS,
	  ISNULL(P.ProductDesc,'CoStar')	AS PRODUCT_FAMILY,
	  P.ProductName						AS PRODUCT_LINE,

      ''							AS QUANTITY_INVOICED,

      --SIL.CurrentTermStartDate									AS QUANTITY_ORDERED_SHIPPED_BillingStartDate,
	  DATEADD(DD, DATEDIFF(DD, 0, SIL.CurrentTermStartDate), 0)		AS QUANTITY_ORDERED_SHIPPED_BillingStartDate,
	  SIL.RenewalDate												AS QUANTITY_ORDERED_SHIPPED_RenewalDate,

      'Y' AS QUOTE_NUM,
      CAST(1 AS NUMERIC(2,1))		AS RCURR_EX_RATE,
      'N' AS RETURN_FLAG,

      GL.REV_ACCTG_SEG1				AS REV_ACCTG_SEG1, 
	  SKUP.MarketName				AS REV_ACCTG_SEG2, 
      GL.REV_ACCTG_SEG3				AS REV_ACCTG_SEG3,
	  SKUP.ProductCategory			AS REV_ACCTG_SEG4,

	  Rule_End_Date,
	  Rule_Start_Date,

	  SIL.ContractID					AS SALES_ORDER,
      SIL.ContractID					AS SALES_ORDER_ID,
      SIL.LineItemID					AS SALES_ORDER_LINE,

	  CAST(C.ContractID AS VARCHAR(10)) + SPACE(1) + CAST(ISNULL(SKUP.SKUID,999999999) AS VARCHAR(100)) + SPACE(1) + CAST(YEAR(SIL.Rule_Start_Date) AS VARCHAR(10)) AS SALES_ORDER_LINE_ID,

      0																	AS SALES_REP_ID,
      ''																AS SALESREP_NAME,
      CAST(CONVERT(VARCHAR(11), SIL.BillingStartDate, 113) AS DATETIME)	AS SCHEDULE_SHIP_DATE,
      'RIG'																AS SEC_ATTR_VALUE,
      CAST(CONVERT(VARCHAR(11), SIL.BillingStartDate, 113) AS DATETIME)	AS SHIP_DATE,
      CAST(CONVERT(VARCHAR(11), SIL.CreatedDate, 113) AS DATETIME)		AS SO_BOOK_DATE,

	  SIL.LineItemID				AS SOB_ID,
      'N'						AS STANDALONE_FLAG,
      'N'						AS STATED_FLAG,
      'INV'						AS TRAN_TYPE,

      MU.MonetaryUnitCode											AS TRANS_CURR_CODE,
      CAST(CONVERT(VARCHAR(11), SIL.CreatedDate, 113) AS DATETIME)	AS TRANS_DATE,	

      'Y'							AS UNBILLED_ACCOUNTING_FLAG,
      'N'							AS UNDELIVERED_FLAG,

      SIL.Amount					AS UNIT_LIST_PRICE, 							
      SIL.Amount					AS UNIT_SELL_PRICE,			

      YEAR(SIL.CurrentTermStartDate)	AS FV_YEAR,

	  0								AS STUB_AMOUNT,

      SIL.CreatedDate					AS CONVERSION_DATA_CreatedDate,
      SIL.LineItemStatusID			AS CANCELLED_FLAG_LineItemStatusID,

      ISNULL(CARVE_IN_DEF_REVENUE_SEG5,''), 
	  ISNULL(UNBILLED_AR_SEG5,''),
	  ISNULL(CARVE_IN_REVENUE_SEG5,''),
	  ISNULL(CARVE_OUT_REVENUE_SEG5,''), 
	  ISNULL(DEF_ACCTG_SEG5,''), 
	  ISNULL(REV_ACCTG_SEG5,''), 
	  ISNULL(LT_DEFERRED_ACCOUNT_SEG5,''),

      ''							AS ATTRIBUTE28,
	  ''							AS NUMBER5,
	  ISNULL(SIL.BundleID,0)		AS BundleID,
	  'N' AS DW_Fl,
	  'N' AS RPro_Fl,
	  'System' AS Created_By,
	  GETDATE() AS Create_Dt,
	  'System' AS Last_Updated_By,
	  GETDATE() AS Last_Update_Dt
FROM RevPro..CurrentTerm_Invoices SIL
	JOIN Staging..[Contract] C 
		ON SIL.Contractid = C.Contractid	
	JOIN Staging..Product P
		ON SIL.ProductID = P.ProductID
	JOIN RevPro..vwAllLocations SiteLoc  
		ON SIL.SiteLocationID = SiteLoc.LocationID
	JOIN RevPro..vwAllLocations BillLoc 
		ON C.BillingLocationID = BillLoc.LocationID
	JOIN Staging..MonetaryUnit MU
		ON SIL.MonetaryUnitID = MU.MonetaryUnitID
	JOIN Staging..CoStarBrand CSB
		ON P.CoStarBrandID = CSB.CoStarBrandID
	JOIN Staging..CoStarSubsidiary CSS
		ON CSB.CoStarSubsidiaryID = CSS.CoStarSubsidiaryID
		AND CSS.CostarSubsidiaryName = 'CoStar Group HQ'
	LEFT JOIN Staging..CustomerInfo CI
		ON SIL.SiteLocationID = CI.locationid 
		  AND CSB.CoStarSubsidiaryID = CI.CoStarSubsidiaryID
	JOIN Staging..RevPro_GL_Mapping GL
		ON SIL.ProductID = GL.ProductID
		AND GL.Active_Fl = 1
	JOIN RevPro..SkuBridge SKUB
		ON SIL.LineItemID = SKUB.LineItemID
	JOIN RevPro..SkuPrice SKUP
		ON SKUB.SkUID = SKUP.SkuID
WHERE SIL.BillingStartDate IS NOT NULL
AND SIL.CurrentTermStartDate IS NOT NULL
AND SIL.RenewalDate IS NOT NULL
AND SIL.RowID BETWEEN @Begin_Count AND @End_Count

SET @Begin_Count = @Begin_Count + @Increment
SET @End_Count = @End_Count + @Increment


END

GO
