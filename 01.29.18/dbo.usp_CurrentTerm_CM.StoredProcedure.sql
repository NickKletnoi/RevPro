USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_CurrentTerm_CM]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_CurrentTerm_CM] 
@StartingDate	DATETIME

AS

/*
==========================================================================
DESCRIPTION

	Func Name:  usp_CurrentTerm_CM
	Purpose:    

	NOTES

	MODIFICATIONS

	Date	    Author		Purpose
	------------------------------------------------

	2017-07-21  Vitaly Romm	Initial version
	
	EXEC RevPro.dbo.usp_CurrentTerm_CM '2017-12-01'

========================================================================== */  

--************************** Start Procedure *************************************************--


/* Get the most active Terms for each contract */
IF OBJECT_ID('RevPro..CurrentTerm_CM') IS NOT NULL
    DROP TABLE CurrentTerm_CM

SELECT RowID = IDENTITY (INT, 1,1),
       L.ContractID,
	   L.LineItemID,
       CONVERT(DATE,L.CurrentTermStartDate) AS CurrentTermStartDate,
       CONVERT(DATE,L.RenewalDate) AS RenewalDate,
       CONVERT(DATE,L.BillingStartDate) AS BillingStartDate,
       SML.[Line Item ID],
	   SML.[Posting Date],
	   SML.[Shipment Date],
	   SML.[Document No_],
       SML.[Line No_],
	   SML.Amount,

	   CAST(
	       CASE WHEN ISDATE(SUBSTRING(SML.[Description 3],1,10)) = 1 THEN SUBSTRING(SML.[Description 3],1,10) 
		        WHEN ISDATE(SUBSTRING(SML.[Description 3],1,8)) = 1 THEN SUBSTRING(SML.[Description 3],1,8) 
	       ELSE CAST(MONTH(SML.[Posting Date]) AS VARCHAR(2)) + '/01/' + CAST(YEAR(SML.[Posting Date]) AS VARCHAR(4)) 
	       END AS DATETIME
		  )		AS RULE_START_DATE,

	   CAST(
	       CASE WHEN ISDATE(SUBSTRING(SML.[Description 3],15,10)) = 1 THEN SUBSTRING(SML.[Description 3],15,10) 
	       WHEN ISDATE(SUBSTRING(SML.[Description 3],13,8)) = 1 THEN SUBSTRING(SML.[Description 3],13,8) 
	       ELSE CONVERT(VARCHAR(12),DATEADD(DAY,-DAY(DATEADD(MONTH,1,SML.[Posting Date])), DATEADD(MONTH,1,SML.[Posting Date])), 101) 
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

INTO CurrentTerm_CM
FROM Staging..[RIG$Sales Cr_Memo Line] SML
	JOIN RevPro..Active_LineItems_Archive L
		ON SML.[Line Item ID] = L.LineItemID
	JOIN (
	      SELECT ContractID, LineItemID, MAX(RunDate) AS RunDate
	      FROM Active_LineItems_Archive
		  GROUP BY ContractID, LineItemID
		 ) A
			ON L.ContractID = A.ContractID
			AND L.LineItemID = A.LineItemID
			AND L.RunDate = A.RunDate
WHERE SML.[Posting Date] BETWEEN DATEADD(DAY,1,EOMONTH(@StartingDate,-1)) AND EOMONTH(@StartingDate)	--Monthly
--WHERE SIL.[Posting Date] = StartingDate	--Daily														--Daily


/* Archive the CM data */
INSERT INTO RevPro..CurrentTerm_CM_Archive
SELECT *, @StartingDate, GETDATE()
FROM RevPro..CurrentTerm_CM



CREATE CLUSTERED INDEX clx_CurrentTerm_CM_Line_Item_ID ON CurrentTerm_CM ([Line Item ID])
CREATE NONCLUSTERED INDEX nclx_CurrentTerm_CM_Posting_Date ON CurrentTerm_CM ([Posting Date])

GO
