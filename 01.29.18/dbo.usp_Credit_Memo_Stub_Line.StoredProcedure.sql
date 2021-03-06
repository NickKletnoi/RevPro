USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_Credit_Memo_Stub_Line]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[usp_Credit_Memo_Stub_Line]
AS

/*
==========================================================================
DESCRIPTION

	Proc Name:  usp_Invoice_Stub_Line
	Purpose:    

	NOTES

	MODIFICATIONS

	Date	    Author		Purpose
	------------------------------------------------

	2017-09-14  Vitaly Romm	Initial version
	
	EXEC RevPro.dbo.usp_Credit_Memo_Stub_Line

==========================================================================*/  

/* Update necessary fields to reflect the stub record */
UPDATE CM
SET Rule_End_Date = CAST(EOMONTH(Rule_Start_Date) AS DATETIME),
    Deal_ID_LocationID = 'S' + Deal_ID_LocationID,
	Sales_Order_Line_ID = 'S' + Sales_Order_Line_ID, 
	Stub_Amount = 2
FROM Revpro..Credit_Memo_Raw CM
	JOIN RevPro..Active_LineItems AL
		ON CM.Sales_Order_Line = AL.LineItemID
WHERE AL.Stub_Fl = 1


/* Update the remaining non stub records to 1 */
UPDATE CM
SET Stub_Amount = 1
FROM Revpro..Credit_Memo_Raw CM
	JOIN Revpro..Credit_Memo_Raw CM2
		ON CM.Sales_Order = CM2.Sales_Order
WHERE LEFT(CM.Sales_Order_Line_ID,1) <> 'S'
AND LEFT(CM2.Sales_Order_Line_ID,1) = 'S'


/* Default to 1 if the stub amount is 0 */
UPDATE CM
SET Stub_Amount = 1
FROM Revpro..Credit_Memo_Raw CM
WHERE Stub_Amount = 0


/* Update the Orig INV Line ID in order to link back to the corresponding Invoice */
UPDATE CM
SET Orig_Inv_Line_ID = INV.Invoice_Line_ID
FROM Staging..Credit_Memo_Feed CM
	JOIN Staging..Invoice_Feed INV
		ON CM.Sales_Order_Line_ID = INV.Sales_Order_Line_ID


/* Update the Ext list/Sell prices for scheduled price scenarios (straightlines) that will include both Step-ups and discount expirations */
UPDATE CM
SET Unit_List_Price = A.Unit_List_Price,
    Unit_Sell_Price = A.Unit_Sell_Price,
	Ext_List_Price = A.Ext_List_Price,
	Ext_Sell_Price = A.Ext_Sell_Price
--SELECT A.*, CM.Rule_Start_Date, CM.Rule_End_Date, CM.Item_Number, CM.*
FROM Revpro..Credit_Memo_Raw CM
	JOIN (
	      SELECT CM.Sales_Order,
		         Unit_List_Price = SLC.WaterFall_Amt/COUNT(CM.Sales_Order_Line),
				 Unit_Sell_Price = SLC.WaterFall_Amt/COUNT(CM.Sales_Order_Line),
				 Ext_List_Price = SLC.Contract_Final_Amt_LessStubAmt/COUNT(CM.Sales_Order_Line),
				 Ext_Sell_Price = SLC.Contract_Final_Amt_LessStubAmt/COUNT(CM.Sales_Order_Line)
	      FROM Revpro..Credit_Memo_Raw CM
			JOIN vwStraightLineContracts SLC
				ON CM.Sales_Order = SLC.ContractID
		  --WHERE CM.Sales_Order = 175582
		  AND CM.Stub_Amount = 1
		  GROUP BY CM.Sales_Order, CM.Stub_Amount, SLC.WaterFall_Amt, SLC.Contract_Final_Amt_LessStubAmt
		 ) A
	ON CM.Sales_Order = A.Sales_Order
	WHERE CM.Stub_Amount = 1



/* Update the Ext list/Sell prices for scheduled price scenarios (straightlines) that will include both Step-ups and discount expirations */
UPDATE CM
SET Unit_List_Price = A.Unit_List_Price,
    Unit_Sell_Price = A.Unit_Sell_Price,
	Ext_List_Price = A.Ext_List_Price,
	Ext_Sell_Price = A.Ext_Sell_Price
--SELECT A.*, CM.Rule_Start_Date, CM.Rule_End_Date, CM.Item_Number, CM.*
FROM Revpro..Invoice_Raw CM
	JOIN (
	      SELECT CM.Sales_Order,
		         Unit_List_Price = SLC.WaterFall_Stub_Amt/COUNT(CM.Sales_Order_Line),
				 Unit_Sell_Price = SLC.WaterFall_Stub_Amt/COUNT(CM.Sales_Order_Line),
				 Ext_List_Price = SLC.WaterFall_Stub_Amt/COUNT(CM.Sales_Order_Line),
				 Ext_Sell_Price = SLC.WaterFall_Stub_Amt/COUNT(CM.Sales_Order_Line)
	      FROM Revpro..Invoice_Raw CM
			JOIN vwStraightLineContracts SLC
				ON CM.Sales_Order = SLC.ContractID
		  --WHERE CM.Sales_Order = 175582
		  AND CM.Stub_Amount = 2
		  GROUP BY CM.Sales_Order, CM.Stub_Amount, SLC.WaterFall_Stub_Amt
		 ) A
	ON CM.Sales_Order = A.Sales_Order
	WHERE CM.Stub_Amount = 2
GO
