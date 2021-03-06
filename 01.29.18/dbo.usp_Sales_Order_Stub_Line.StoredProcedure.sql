USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_Sales_Order_Stub_Line]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_Sales_Order_Stub_Line]
AS

/* ==========================================================================
DESCRIPTION

	Proc Name:  usp_Sales_Order_Stub_Line
	Purpose:    

	NOTES

	MODIFICATIONS

	Date	    Author		Purpose
	------------------------------------------------

	2017-09-14  Vitaly Romm	Initial version
	
	EXEC RevPro.dbo.usp_Sales_Order_Stub_Line

========================================================================== */


/* Update the partial month value for the stub month if any exist */
UPDATE SOR
SET Deal_ID_LocationID = 'S' + Deal_ID_LocationID,
	Sales_Order_Line_ID = 'S' + Sales_Order_Line_ID,
	Rule_End_Date = EOMONTH(AL.CurrentTermStartDate),
	Stub_Amount = 2,
	Ext_List_Price = Stub_Amount,
    Ext_Sell_Price = Stub_Amount,
	Unit_List_Price = Stub_Amount, 
	Unit_Sell_Price = Stub_Amount
FROM Revpro..Sales_Order_Raw SOR
	JOIN RevPro..Active_LineItems AL
		ON SOR.Sales_Order_Line = AL.LineItemID
WHERE AL.Stub_Fl = 1



/* Update the Stub value to 1 for all of the non stub lines that contain a stub record in their term period */
UPDATE SOR
SET Stub_Amount = 1
--SELECT SOR.*
FROM Revpro..Sales_Order_Raw SOR
	JOIN Revpro..Sales_Order_Raw SOR2
		ON SOR.Sales_Order = SOR2.Sales_Order
WHERE LEFT(SOR.Sales_Order_Line_ID,1) <> 'S'
AND LEFT(SOR2.Sales_Order_Line_ID,1) = 'S'



/* Just take the first year of the multi year term by splitting out the first year */
UPDATE SOR
SET Rule_End_Date = CASE WHEN DATEDIFF(MM, Rule_Start_Date, Rule_End_Date) > 12 THEN DATEADD(YEAR,-1,Rule_End_Date) ELSE Rule_End_Date END
FROM Revpro..Sales_Order_Raw SOR



/* Update the Ext list/Sell prices for scheduled price scenarios (straightlines) that will include both Step-ups and discount expirations */
UPDATE SOR
SET Unit_List_Price = A.Unit_List_Price,
    Unit_Sell_Price = A.Unit_Sell_Price,
	Ext_List_Price = A.Ext_List_Price,
	Ext_Sell_Price = A.Ext_Sell_Price
--SELECT A.*, SOR.*
FROM Revpro..Sales_Order_Raw SOR
	JOIN (
	      SELECT SOR.Sales_Order,
		         Unit_List_Price = CASE SOR.Stub_Amount WHEN 2 THEN (SLC.WaterFall_Stub_Amt/COUNT(SOR.Sales_Order_Line)) ELSE (SLC.WaterFall_Amt/COUNT(SOR.Sales_Order_Line)) END,
				 Unit_Sell_Price = CASE SOR.Stub_Amount WHEN 2 THEN (SLC.WaterFall_Stub_Amt/COUNT(SOR.Sales_Order_Line)) ELSE (SLC.WaterFall_Amt/COUNT(SOR.Sales_Order_Line)) END,
				 Ext_List_Price = CASE SOR.Stub_Amount WHEN 2 THEN (SLC.WaterFall_Stub_Amt/COUNT(SOR.Sales_Order_Line)) ELSE (SLC.Contract_Final_Amt_LessStubAmt/COUNT(SOR.Sales_Order_Line)) END,
				 Ext_Sell_Price = CASE SOR.Stub_Amount WHEN 2 THEN (SLC.WaterFall_Stub_Amt/COUNT(SOR.Sales_Order_Line)) ELSE (SLC.Contract_Final_Amt_LessStubAmt/COUNT(SOR.Sales_Order_Line)) END
	      FROM Revpro..Sales_Order_Raw SOR
			JOIN vwStraightLineContracts SLC
				ON SOR.Sales_Order = SLC.ContractID
		  WHERE SLC.StraightLineStatusFlg = 1
		  GROUP BY SOR.Sales_Order, SOR.Stub_Amount, SLC.WaterFall_Stub_Amt, SLC.WaterFall_Amt, SLC.Contract_Final_Amt_LessStubAmt
		 ) A
	ON SOR.Sales_Order = A.Sales_Order


/* Escalation percent increase at the start of a new term by DATE */
UPDATE SOR
SET Unit_List_Price = Unit_List_Price * (LIE.EscalationPct * .01 + 1),
    Unit_Sell_Price = Unit_Sell_Price * (LIE.EscalationPct * .01 + 1)
FROM Sales_Order_Raw SOR
	JOIN Active_LineItems AL
		ON SOR.Sales_Order = AL.ContractID
	JOIN Staging..LineItemEscalation LIE
		ON AL.LineItemID = LIE.LineItemID
WHERE SOR.Rule_Start_Date = LIE.FirstEscalationDate	
AND AL.StraightLine_Fl = 0		


/* Escalation percent increase at the start of a new term by MONTH */
UPDATE SOR
SET Unit_List_Price = Unit_List_Price * (A.EscalationPct * .01 + 1),
    Unit_Sell_Price = Unit_Sell_Price * (A.EscalationPct * .01 + 1)
--SELECT *
FROM RevPro..Sales_Order_Raw SOR
	JOIN
	(
	 SELECT AL.ContractID, AL.CurrentTermStartDate, AL.RenewalDate, LIE.EscalationPct,
	   MIN(LIPD.EffectiveDate) AS EffectiveDate,
	   MIN(DATEADD(MONTH, LIE.FirstEscalationMonth - 1, LIPD.EffectiveDate)) AS FirstEscalationDate
	 FROM Active_LineItems AL
		JOIN Staging..LineItemEscalation  LIE
			ON AL.LineItemID = LIE.LineItemID
		JOIN Staging..LineItemPricingDetail LIPD
			ON LIE.LineItemID = LIPD.LineItemID
	 WHERE AL.StraightLine_Fl = 0		
	 --AND AL.ContractID = 12767
	 GROUP BY AL.ContractID, AL.CurrentTermStartDate, AL.RenewalDate, LIE.EscalationPct
	) A
ON SOR.Sales_Order = A.ContractID
AND YEAR(SOR.Rule_Start_Date) = YEAR(A.FirstEscalationDate)
AND MONTH(SOR.Rule_Start_Date) = MONTH(A.FirstEscalationDate)



/* Generate the Extended list/sell prices for all 12 month terms but not for stubs. The stub amount will be the same for both the ext and unit values */
UPDATE SOR
SET Ext_List_Price = Unit_List_Price * (
                                        DATEDIFF(MONTH, CAST(RULE_START_DATE AS DATETIME), Rule_End_Date) +
										CASE WHEN DAY(CAST(RULE_START_DATE AS DATETIME)) < DAY(Rule_End_Date)
											 THEN 1 ELSE 0 
										END + CASE WHEN DAY(Rule_End_Date) <> DAY(EOMONTH(Rule_End_Date)) THEN - 1 ELSE 0 END	--We don't want to inclulde a StubTail month
										) ,
	Ext_Sell_Price = Unit_Sell_Price * (
                                        DATEDIFF(MONTH, CAST(RULE_START_DATE AS DATETIME), Rule_End_Date) +
										CASE WHEN DAY(CAST(RULE_START_DATE AS DATETIME)) < DAY(Rule_End_Date)
											 THEN 1 ELSE 0 
										END + CASE WHEN DAY(Rule_End_Date) <> DAY(EOMONTH(Rule_End_Date)) THEN - 1 ELSE 0 END
										) 
FROM Revpro..Sales_Order_Raw SOR
	JOIN RevPro..Active_LineItems AL
		ON SOR.Sales_Order_Line = AL.LineItemID
WHERE AL.Stub_Fl = 0 
AND AL.StraightLine_Fl = 0



/* Update the Stub Tail amounts and then add it to the Ext list/sell prices */
UPDATE SOR
SET Ext_List_Price = Ext_List_Price + (ISNULL(CAST(SOR.Unit_Sell_Price AS NUMERIC (18, 4)),0)/DAY(EOMONTH(SOR.Rule_End_Date))) * DAY(SOR.Rule_End_Date),
    Ext_Sell_Price = Ext_Sell_Price + (ISNULL(CAST(SOR.Unit_Sell_Price AS NUMERIC (18, 4)),0)/DAY(EOMONTH(SOR.Rule_End_Date))) * DAY(SOR.Rule_End_Date)
FROM Revpro..Sales_Order_Raw SOR
	JOIN RevPro..Active_LineItems AL
		ON SOR.Sales_Order_Line = AL.LineItemID
WHERE AL.StubTail_Fl = 1
AND AL.StraightLine_Fl = 0


/* We probably don't need this anymore but in case something slips through the cracks we'll disregard it. These are probably terminated lines */
DELETE 
--SELECT * 
FROM Revpro..Sales_Order_Raw
WHERE Unit_Sell_Price = 0



/* Update the archive table to reflect the actual values. We'll need them up-to-date if we have to pull the record back out */
UPDATE ALA
SET CurrentTermStartDate = SOR.Rule_Start_Date,
    RenewalDate= SOR.Rule_End_Date,
	DiscountedMonthlyPrice = SOR.Unit_List_Price
FROM Active_LineItems_Archive ALA
	JOIN Sales_Order_Raw SOR
		ON ALA.ContractID = SOR.Sales_Order
		AND ALA.LineItemID = SOR.Sales_Order_Line
	JOIN (SELECT ContractID, LineItemID, MAX(RunDate) AS RunDate
	      FROM Active_LineItems_Archive
		  GROUP BY ContractID, LineItemID) A
			ON ALA.ContractID = A.ContractID
			AND ALA.LineItemID = A.LineItemID
			AND ALA.RunDate = A.RunDate

GO
