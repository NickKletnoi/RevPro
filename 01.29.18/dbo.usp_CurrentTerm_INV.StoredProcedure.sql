USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_CurrentTerm_INV]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_CurrentTerm_INV] 
@StartingDate	DATETIME

AS

/* ==========================================================================
DESCRIPTION

	Func Name:  usp_CurrentTerm_INV
	Purpose:    

	NOTES

	MODIFICATIONS

	Date	    Author		Purpose
	------------------------------------------------

	2017-07-21  Vitaly Romm	Initial version
	
	EXEC RevPro..usp_CurrentTerm_INV '2017-12-01'

========================================================================== */  

--************************** Start Procedure *************************************************--


/* Get the most active Terms for each contract */
IF OBJECT_ID('RevPro..CurrentTerm_Invoices') IS NOT NULL
    DROP TABLE RevPro..CurrentTerm_Invoices

SELECT RowID = IDENTITY (INT, 1,1),
       L.ContractID,
	   L.LineItemID,
       CONVERT(DATE,L.CurrentTermStartDate) AS CurrentTermStartDate,
       CONVERT(DATE,L.RenewalDate) AS RenewalDate,
       CONVERT(DATE,L.BillingStartDate) AS BillingStartDate,
       SIL.[Line Item ID],
	   SIL.[Posting Date],
	   SIL.[Shipment Date],
	   SIL.[Document No_],
       SIL.[Line No_],
	   SIL.Amount,

	   CAST(
	       CASE WHEN ISDATE(SUBSTRING(SIL.[Description 3],1,10)) = 1 THEN SUBSTRING(SIL.[Description 3],1,10) 
		        WHEN ISDATE(SUBSTRING(SIL.[Description 3],1,8)) = 1 THEN SUBSTRING(SIL.[Description 3],1,8) 
	       ELSE CAST(MONTH(SIL.[Posting Date]) AS VARCHAR(2)) + '/01/' + CAST(YEAR(SIL.[Posting Date]) AS VARCHAR(4)) 
	       END AS DATETIME
		  )		AS RULE_START_DATE,

	   CAST(
	       CASE WHEN ISDATE(SUBSTRING(SIL.[Description 3],15,10)) = 1 THEN SUBSTRING(SIL.[Description 3],15,10) 
	       WHEN ISDATE(SUBSTRING(SIL.[Description 3],13,8)) = 1 THEN SUBSTRING(SIL.[Description 3],13,8) 
	       ELSE CONVERT(VARCHAR(12),DATEADD(DAY,-DAY(DATEADD(MONTH,1,SIL.[Posting Date])), DATEADD(MONTH,1,SIL.[Posting Date])), 101) 
	       END AS DATETIME
		  )		AS RULE_END_DATE,

	   L.DiscountedMonthlyPrice,
	   L.OriginalMonthlyPrice,
	   L.ProductID,
	   L.MonetaryUnitID,
	   L.SiteLocationID,
       L.LineItemStatusID, 
	   L.LineItemTypeID,
	   L.LineItemInvoiceConfigurationID, 
	   L.BundleID,
	   L.CreatedDate

INTO CurrentTerm_Invoices
FROM Staging..[RIG$Sales Invoice Line] SIL
	JOIN RevPro..Active_LineItems_Archive L
		ON SIL.[Line Item ID] = L.LineItemID
	JOIN (
	      SELECT ContractID, LineItemID, MAX(RunDate) AS RunDate
	      FROM Active_LineItems_Archive
		  GROUP BY ContractID, LineItemID
		 ) A
			ON L.ContractID = A.ContractID
			AND L.LineItemID = A.LineItemID
			AND L.RunDate = A.RunDate
WHERE SIL.[Posting Date] BETWEEN DATEADD(DAY,1,EOMONTH(@StartingDate,-1)) AND EOMONTH(@StartingDate)	--Monthly
--WHERE SIL.[Posting Date] = StartingDate	--Daily


CREATE CLUSTERED INDEX clx_CurrentTerm_Invoices_Line_Item_ID ON CurrentTerm_Invoices ([Line Item ID])
CREATE NONCLUSTERED INDEX nclx_CurrentTerm_Invoices_Posting_Date ON CurrentTerm_Invoices ([Posting Date])


/* Archive the INV data */
INSERT INTO RevPro..CurrentTerm_Invoices_Archive
SELECT *, @StartingDate, GETDATE() AS RunDate
FROM RevPro..CurrentTerm_Invoices
GO
