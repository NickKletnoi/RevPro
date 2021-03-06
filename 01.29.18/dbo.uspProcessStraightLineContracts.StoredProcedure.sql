USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[uspProcessStraightLineContracts]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[uspProcessStraightLineContracts]
AS

DECLARE @CURRENT_CONTRACTID INT

TRUNCATE TABLE [stg].[Contract_Input_List];

WITH SDSCPRD as (
SELECT 
LI.ContractID,
LID.DiscountMonth AS DM,
SUM(LI.EffectiveDiscountAmount) AS  Amt,
COUNT(*) AS Cnt
FROM 
Staging..LineItem LI 
JOIN Staging..LineItemDiscount LID 
ON LI.LineItemID=LID.LineItemID 
GROUP BY LI.ContractID,LID.DiscountMonth
HAVING COUNT(*)=1 AND SUM(LI.EffectiveDiscountAmount)>0.00
),
SCD2 AS (
SELECT DISTINCT CONTRACTID FROM SDSCPRD WHERE DM>1 )
INSERT [stg].[Contract_Input_List] ([ContractID],[StatusFlg])
SELECT DISTINCT [ContractID],'U'
FROM RevPro..[Active_SOFile] ASO
WHERE ASO.ContractID  IN 
(
SELECT DISTINCT LI1.ContractID from Staging..LineItem LI1 
JOIN Staging..LineItemEscalation LIE 
ON LI1.LineItemID=LIE.LineItemID
WHERE (LIE.FirstEscalationMonth IS NOT NULL) 
GROUP BY LI1.ContractID
HAVING (SUM(ISNULL(LIE.EscalationAmount,0))>0.00)
UNION
SELECT DISTINCT LI2.ContractID FROM  Staging..LineItem LI2 
JOIN  Staging..LineItemDiscount LID  
ON LI2.LineItemID=LID.LineItemID
JOIN SDSCPRD SDC ON SDC.ContractID=LI2.ContractID AND SDC.DM=LID.DiscountMonth
WHERE (LID.DiscountMonth IS NOT NULL) AND LI2.ContractID NOT IN (SELECT DISTINCT ContractID FROM SCD2)
GROUP BY LI2.ContractID 
HAVING (SUM(ISNULL(LID.DiscountAmount,0))>0.00)
EXCEPT (
SELECT DISTINCT CONTRACTID FROM dbo.StraightLineContracts
UNION
SELECT DISTINCT CONTRACTID FROM dbo.StraightLineDiscountContracts
));


 DECLARE C CURSOR FOR
 SELECT DISTINCT [ContractID] FROM [stg].[Contract_Input_List]
   
 OPEN C
 FETCH C into @CURRENT_CONTRACTID
 WHILE @@FETCH_STATUS = 0
 BEGIN

   EXEC [dbo].[usp_CreateStraightLineWaterfall] @CURRENT_CONTRACTID;
   EXEC [dbo].[usp_CreateStraightLineDiscountWaterfall] @CURRENT_CONTRACTID;

	   UPDATE CIL SET CIL.StatusFlg='P', CIL.AuditDate=GETDATE() 
			FROM [stg].[Contract_Input_List] CIL 
				WHERE CIL.ContractID=@CURRENT_CONTRACTID;

FETCH C into @CURRENT_CONTRACTID
 END

 CLOSE C
 DEALLOCATE C

--DELETE FROM dbo.StraightLineContracts WHERE Contract_Final_Amt IS NULL;
--DELETE FROM dbo.StraightLineDiscountContracts WHERE Contract_Final_Amt IS NULL;


GO
