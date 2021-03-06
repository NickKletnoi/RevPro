USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_Create_Active_Terms]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_Create_Active_Terms] 
@StartingDate	DATETIME

AS

/*
==========================================================================
DESCRIPTION

	Func Name:  usp_Create_Active_Terms
	Purpose:    

	NOTES

	MODIFICATIONS

	Date	    Author		Purpose
	------------------------------------------------

	2017-07-21  Vitaly Romm	Initial version
	
	EXEC RevPro.dbo.usp_Create_Active_Terms '2017-12-01'
	
========================================================================== */  

--DECLARE @StartingDate DATETIME = '2016-11-01'

DECLARE @OneTimeAdjustmentID	INT = 58

--************************** Start Procedure *************************************************--

/* Get the most active Terms for each contract */

TRUNCATE TABLE Active_LineItems

INSERT INTO Active_LineItems
SELECT DISTINCT
       L.ContractID,
	   L.LineItemID,
       CONVERT(DATE,L.CurrentTermStartDate) AS CurrentTermStartDate,
       CONVERT(DATE,L.RenewalDate) AS RenewalDate,
       CONVERT(DATE,L.BillingStartDate) AS BillingStartDate,
       L.DiscountedMonthlyPrice,
	   L.OriginalMonthlyPrice,
	   L.ProductID,
	   L.MonetaryUnitID,
	   L.SiteLocationID,
       L.LineItemStatusID, 
	   L.LineItemTypeID,
	   L.LineItemInvoiceConfigurationID, 
	   L.BundleID,
	   L.CreatedDate,	
       0 AS Stub_Fl,
	   0 AS StubTail_Fl,
	   0 AS StraightLine_Fl
FROM Staging..LineItem L
	JOIN Active_SOFile SOF
		ON L.ContractID = SOF.ContractID
	JOIN SKUBridge SKU
		ON L.LineItemID = SKU.LineItemID
/*	Monthly */
WHERE (CAST(L.CurrentTermStartDate AS DATE) BETWEEN DATEADD(DAY,1,EOMONTH(@StartingDate,-1)) AND EOMONTH(@StartingDate)
	OR (MONTH(L.CurrentTermStartDate) = CASE WHEN MONTH(@StartingDate) = 1 THEN 12 ELSE MONTH(DATEADD(MONTH, -1, @StartingDate)) END AND
		YEAR(L.CurrentTermStartDate) = CASE WHEN MONTH(@StartingDate) = 1 THEN YEAR(@StartingDate) - 1 ELSE YEAR(@StartingDate) END AND 
		DAY(L.CurrentTermStartDate) <> 1))
--WHERE L.ContractID = 175582



/* Cancelled Contracts */
INSERT INTO Active_LineItems
SELECT ALA.ContractID,
	   ALA.LineItemID,
       CONVERT(DATE,ALA.CurrentTermStartDate) AS CurrentTermStartDate,
	   CONVERT(DATE,LIPD.EffectiveDate) AS RenewalDate,		--New effective date since the contract was cancelled.
       CONVERT(DATE,ALA.BillingStartDate) AS BillingStartDate,
       ALA.DiscountedMonthlyPrice,
	   ALA.OriginalMonthlyPrice,
	   ALA.ProductID,
	   ALA.MonetaryUnitID,
	   ALA.SiteLocationID,
       ALA.LineItemStatusID, 
	   ALA.LineItemTypeID,
	   ALA.LineItemInvoiceConfigurationID, 
	   ALA.BundleID,
	   ALA.CreatedDate,	
       0 AS Stub_Fl,
	   0 AS StubTail_Fl,
	   0 AS StraightLine_Fl
FROM Active_LineItems_Archive ALA
	JOIN Staging..LineItemPricingDetail LIPD
		ON ALA.LineItemID = LIPD.LineItemID
		AND LIPD.LineItemPricingDetailSubTypeID = 10	--Close-out Entry
	LEFT JOIN Active_LineItems AL						--To make sure that the LineItem ID is not already in the table. In case there was an event and a cancellation in the same month.
		ON LIPD.LineItemID = AL.LineItemID
WHERE MONTH(LIPD.EffectiveDate) = MONTH(@StartingDate)
AND YEAR(LIPD.EffectiveDate) = YEAR(@StartingDate)
AND AL.LineItemID IS NULL	
AND ALA.ContractID NOT IN (
                           SELECT DISTINCT L.ContractID 
                           FROM Staging..LineItem L
								JOIN Staging..LineItemPricingDetail LIPD
									ON L.LineItemID = LIPD.LineItemID
					       WHERE LineItemPricingDetailSubTypeID <> 10
						   AND MONTH(EffectiveDate) = MONTH(@StartingDate)
						   AND YEAR(EffectiveDate) = YEAR(@StartingDate)
					      )
--AND ALA.ContractID = 175582


/* Straightline Contract Scenarios so we need to update the flag */
UPDATE AL
SET StraightLine_Fl = 1
FROM Active_LineItems AL
	JOIN vwStraightLineContracts SC
		ON AL.ContractID = SC.ContractID
WHERE SC.StraightLine_Flg = 1


/* Nonsense One-Time Fee Adjustment disaster. It will go away with the automated credit memo */
DELETE AL
--SELECT DISTINCT AL.* 
FROM RevPro..Active_LineItems AL
		JOIN RevPro..Active_LineItems AL2
			ON AL.ContractID = AL2.ContractID
WHERE AL.CurrentTermStartDate = AL2.CurrentTermStartDate
AND AL.RenewalDate < AL2.RenewalDate
AND AL.ProductID = @OneTimeAdjustmentID --One-Time Fee Adjustment



/* Update the Stub_Fl if it's the first term of the contract and it starts with a partial month (stub) */
UPDATE AL
SET Stub_Fl = 1
FROM Active_LineItems AL
WHERE DAY(CurrentTermStartDate) <> 1
AND MONTH(CurrentTermStartDate) = MONTH(@StartingDate)	--We only mark the stub period as the stub during the actual month of the stub



/* Convert the stub CurrentTermStartDate to the first of the following month if we are pulling in the month after the stub  */
UPDATE Active_LineItems
SET CurrentTermStartDate = DATEADD(D, 1, EOMONTH(CurrentTermStartDate))
WHERE Stub_Fl = 0	
AND DATEADD(D, 1, EOMONTH(CurrentTermStartDate)) <= RenewalDate
AND DAY(CurrentTermStartDate) <> 1



/* Update the DiscountedMonthlyPrice with the OriginalMonthlyprice if the line has been cancelled or terminated. 
   They zero out the DiscountedMonthlyPrice values but we still need to count them from the OriginalMonthlyprice. */
UPDATE Active_LineItems
SET DiscountedMonthlyPrice = OriginalMonthlyPrice
WHERE ISNULL(OriginalMonthlyPrice,1) NOT IN (0,1)



/* When we have a price increase during the term period we need to bring in the old line and then reprice it along with the stub if there is one and then close it.
   For the second line, it will start at the new term date and then go on and follow the normal process 
   1. 7/1/2017		06/30/2018

   2. 7/1/2017		10/5/2017		--We need to close the end date
   3. 10/6/2017		10/31/2017		--New term and this is the stub for it
*/
INSERT INTO Active_LineItems
SELECT DISTINCT ALA.ContractID, ALA.LineItemID, ALA.CurrentTermStartDate, ALA.RenewalDate, ALA.BillingStartDate, ALA.DiscountedMonthlyPrice,
                ALA.OriginalMonthlyPrice, ALA.ProductID, ALA.MonetaryUnitID, ALA.SiteLocationID, ALA.LineItemStatusID, ALA.LineItemTypeID,
			    ALA.LineItemInvoiceConfigurationID, ALA.BundleID, ALA.CreatedDate, ALA.Stub_Fl, ALA.StubTail_Fl, ALA.StraightLine_Fl
FROM Active_LineItems_Archive ALA
	JOIN (
	      SELECT ALA.ContractID, MAX(ALA.CurrentTermStartDate) AS CurrentTermStartDate
		  FROM Active_LineItems_Archive ALA
			JOIN Active_LineItems AL
				ON ALA.ContractID = AL.ContractID
				AND ALA.CurrentTermStartDate < AL.CurrentTermStartDate --AND AL.ContractID = 178760
				AND DATEADD(MONTH, 1, ALA.CurrentTermStartDate) >= AL.CurrentTermStartDate
		  -- AL.Stub_Fl = 0	--Check this
		  GROUP BY ALA.ContractID
		 ) AL
		ON ALA.ContractID = AL.ContractID
		AND ALA.CurrentTermStartDate = AL.CurrentTermStartDate
WHERE ALA.Stub_Fl = 0


/* This is where we close the first term to the day before the first day of the new term (stub period) 
   This is how step 1 goes to step 2 */
UPDATE AL
SET StubTail_Fl = 1,
    RenewalDate = DATEADD(DAY,-1,AL2.CurrentTermStartDate)
FROM Active_LineItems AL
	JOIN Active_LineItems AL2
		ON AL.ContractID = AL2.ContractID
WHERE AL.CurrentTermStartDate < AL2.CurrentTermStartDate
AND AL.RenewalDate >= AL2.RenewalDate



/* Continuation, now that we closed the old term it might end up with a tail stub */
UPDATE Active_LineItems
SET StubTail_Fl = 1
WHERE DAY(RenewalDate) <> DAY(EOMONTH(RenewalDate))



/* Continuation, we need to add the existing term price to the one time adjustment increase (product 58) */
UPDATE AL
SET DiscountedMonthlyPrice = DiscountedMonthlyPrice + NewTotal
FROM Active_LineItems AL
	JOIN (
	      SELECT ContractID, SUM(DiscountedMonthlyPrice)/COUNT(*) AS NewTotal 
	      FROM Active_LineItems 
		  WHERE ISNULL(DiscountedMonthlyPrice,0) <> 0 AND ProductID <> @OneTimeAdjustmentID 
		  GROUP BY ContractID
		 ) A
		ON AL.ContractID = A.ContractID
WHERE ProductID = @OneTimeAdjustmentID



/* This is in regards to product 58. Contract 178760 is an example of this scenario */ 
DELETE AL
FROM Active_LineItems AL
JOIN (
	  SELECT AL.ContractID, MIN(CurrentTermStartDate) AS MIN_CurrentTermStartDate
	  FROM Active_LineItems AL
		JOIN (
			  SELECT ContractID, COUNT(DISTINCT CurrentTermStartDate) AS Num_CurrentTermStartDate
			  FROM Active_LineItems
			  WHERE MONTH(CurrentTermStartDate) < MONTH(@StartingDate)
			  GROUP BY ContractID
			  HAVING COUNT(DISTINCT CurrentTermStartDate) > 1
			  ) A
		ON AL.ContractID = A.ContractID
	  GROUP BY AL.ContractID
	 ) B
	ON AL.ContractID = B.ContractID
	AND AL.CurrentTermStartDate = B.MIN_CurrentTermStartDate



/* Update the renewal date for product terms of 58 to the real renewal date */
UPDATE AL
SET CurrentTermStartDate = DATEADD(D, 1, EOMONTH(CurrentTermStartDate)),
    RenewalDate = A.RenewalDate
FROM Active_LineItems AL
	JOIN (
		  SELECT ContractID, MAX(RenewalDate) AS RenewalDate
	      FROM Active_LineItems_Archive ALA
		  GROUP BY ContractID
		  ) A
		ON AL.ContractID = A.ContractID
WHERE AL.ProductID = @OneTimeAdjustmentID
AND MONTH(CurrentTermStartDate) < MONTH(@StartingDate)



/* Archive the lines */
INSERT INTO Active_LineItems_Archive
SELECT *, @StartingDate, GETDATE()
FROM Active_LineItems



GO
