USE [RevPro]
GO
/****** Object:  View [dbo].[vwStraightLineContracts]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE VIEW [dbo].[vwStraightLineContracts]
	AS
	SELECT SLC.ContractID, SLC.Waterfall_Amt, SLC.Waterfall_Stub_Amt, SLC.Contract_Final_Amt, 
	(SLC.Contract_Final_Amt-SLC.Waterfall_Stub_Amt) as Contract_Final_Amt_LessStubAmt,
	 'E' as StraightLineType, CASE WHEN (NFTC.ContractID IS NOT NULL) THEN 0 ELSE 1 END AS StraightLineStatusFlg
	--(SELECT MAX(LI4.CurrentTermStartDate)  FROM Staging..LineItem LI4  WHERE LI4.ContractID=SLC.ContractID) as CurrentTermStart,
	--(SELECT DATEDIFF(mm,MAX(LI5.CurrentTermStartDate),MAX(LI5.RenewalDate)) FROM Staging..LineItem LI5 WHERE LI5.ContractID=SLC.ContractID) as CurrentTermPeriod
	FROM dbo.StraightLineContracts SLC LEFT JOIN
	(SELECT contractid, COUNT(DISTINCT L.RenewalDate) RD 
							FROM Staging..LineItem L
							GROUP BY ContractID
							HAVING COUNT(DISTINCT L.RenewalDate)>1 ) NFTC ON SLC.ContractID=NFTC.ContractID
	WHERE (SLC.StraightLine_Flg=0 OR SLC.StraightLine_Flg=1) 
    AND ( SLC.Contract_Final_Amt > 0 ) AND ( SLC.Waterfall_Stub_Amt  < SLC.Waterfall_Amt )

	UNION

    SELECT SLDC.ContractID, SLDC.Waterfall_Amt, SLDC.Waterfall_Stub_Amt, SLDC.Contract_Final_Amt, 
	(SLDC.Contract_Final_Amt-SLDC.Waterfall_Stub_Amt) as Contract_Final_Amt_LessStubAmt,
	 'D' as StraightLineType, CASE WHEN (NFTC.ContractID IS NOT NULL) THEN 0 ELSE 1 END AS StraightLineStatusFlg
	--(SELECT MAX(LI6.CurrentTermStartDate)  FROM Staging..LineItem LI6  WHERE LI6.ContractID=SLDC.ContractID) as CurrentTermStart,
	--(SELECT DATEDIFF(mm,MAX(LI7.CurrentTermStartDate),MAX(LI7.RenewalDate)) FROM Staging..LineItem LI7 WHERE LI7.ContractID=SLDC.ContractID) as CurrentTermPeriod
	FROM dbo.StraightLineDiscountContracts SLDC LEFT JOIN
	(SELECT contractid, COUNT(DISTINCT L.RenewalDate) RD 
							FROM Staging..LineItem L
							GROUP BY ContractID
							HAVING COUNT(DISTINCT L.RenewalDate)>1 ) NFTC ON SLDC.ContractID=NFTC.ContractID
	WHERE (SLDC.StraightLine_Flg=0 OR SLDC.StraightLine_Flg=1) 
    AND ( SLDC.Contract_Final_Amt > 0 ) AND ( SLDC.Waterfall_Stub_Amt  < SLDC.Waterfall_Amt )










GO
