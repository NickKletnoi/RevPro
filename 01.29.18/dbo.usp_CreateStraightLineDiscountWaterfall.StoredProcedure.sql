USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreateStraightLineDiscountWaterfall]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
-----------------------------------------------------
EXEC  [dbo].[usp_CreateStraightLineDiscountWaterfall] 187964 
------------------------------------------------------
SELECT * FROM dbo.StraightLineDiscountContracts where contractid=187964

SELECT * FROM dbo.LineItem where contractid=187964

TRUNCATE TABLE Staging..StraightLineDiscountContracts
SELECT * FROM Staging..StraightLineDiscountContracts

EXEC [dbo].[uspProcessStraightLineDiscountContracts]

*/

CREATE PROC [dbo].[usp_CreateStraightLineDiscountWaterfall]
@CONTRACTID INT=187964
AS

BEGIN TRY

---- Error handling
DECLARE @PROCEDURE_NAME Varchar(150)='usp_CreateStraightLineDiscountWaterfall'
DECLARE @VARIABLE_VALUES Varchar(8000)

------  Declare Period vars 
DECLARE @CURRENT_TERM INT
DECLARE @RENEWALS INT
DECLARE @DISCOUNT_MTH_START INT
DECLARE @TRUE_INI_PRD INT
DECLARE @TRUE_DSC_PRD INT
DECLARE @TRUE_TERM NUMERIC(18,4)
------- Declare flags vars
DECLARE @STRAIGHT_LINE_CONTRACT_FLG BIT=0 
DECLARE @CONTRACT_STRLN_PROCESSED INT
DECLARE @STUB_INVOLVED_FLG BIT
------ Declare money vars
DECLARE @CONTRACT_INITAL_AMT MONEY
DECLARE @CONTRACT_FINAL_AMT MONEY
DECLARE @CONTRACT_DISCOUNT_AMT MONEY
DECLARE @CONTRACT_FINAL_MTH_AMT MONEY
DECLARE @CONTRACT_REG_MTH_AMT MONEY
DECLARE @CONTRACT_DSC_MTH_AMT MONEY
DECLARE @CONTRACT_DSC_PRCT NUMERIC(18,4) 
------- Declare Dates vars
DECLARE @CURRENT_TERM_START_DATE DATE
DECLARE @FIRST_MTH_START_DATE DATE
------- Declare Stub vars
DECLARE @STUB_DIFF_DAYS INT
DECLARE @STUB_FRACTION NUMERIC(18,4)
DECLARE @STUB_MTH_TOTAL_DAYS INT
DECLARE @STUB_START DATE
DECLARE @STUB_END DATE
DECLARE @STUB_START_DAY INT
DECLARE @STUB_AMT MONEY
DECLARE @WATERFALL_AMT MONEY
DECLARE @WATERFALL_STUB_AMT MONEY
----------------------------------
--- Declare Grand variables ------

DECLARE @GRAND_TOTAL_CONTRACT_AMT MONEY
DECLARE @GRAND_TOTAL_STRAIGHT_AMT MONEY
DECLARE @GRAND_WATERFALL_AMT MONEY
DECLARE @GRAND_WATERFALL_STUB_AMT MONEY
DECLARE @GRAND_TOTAL_CONTRACT_FINAL_AMT MONEY
-----------------------------------------------
--- clear temp container ----------------------

TRUNCATE TABLE [stg].StraightLineDiscountContracts;

--------------------------  Period calculations start below ---------------

SELECT @CURRENT_TERM=DATEDIFF(mm,MAX(CurrentTermStartDate),MAX(RenewalDate)) FROM Staging..LineItem  WHERE ContractID=@CONTRACTID;
SELECT @CONTRACT_STRLN_PROCESSED=COUNT(*) FROM vwStraightLineContracts WHERE ContractID=@CONTRACTID;
SELECT @RENEWALS=COUNT(DISTINCT RenewalDate) from Staging..LineItem WHERE ContractID=@CONTRACTID AND RenewalDate IS NOT NULL;

---- Calcualte Simple Stubs ---------------------

SELECT @STUB_START=MAX(CurrentTermStartDate)  FROM Staging..LineItem  WHERE ContractID=@CONTRACTID;
SELECT @STUB_END=MAX(EOMONTH(CurrentTermStartDate)) FROM Staging..LineItem  WHERE ContractID=@CONTRACTID;
SELECT @STUB_MTH_TOTAL_DAYS=DAY(@STUB_END)
SELECT @STUB_START_DAY=DAY(@STUB_START)
SELECT @STUB_DIFF_DAYS=(@STUB_MTH_TOTAL_DAYS-@STUB_START_DAY)+1
SELECT @STUB_FRACTION=CAST(@STUB_DIFF_DAYS AS NUMERIC(18,4))/CAST(@STUB_MTH_TOTAL_DAYS AS NUMERIC(18,4))
SELECT @DISCOUNT_MTH_START=MAX(DiscountMonth) 
FROM Staging..LineItemDiscount LE 
     JOIN Staging..LineItem L ON LE.LineItemID=L.LineItemID
                                          WHERE ContractID=@CONTRACTID
SELECT @TRUE_DSC_PRD=MAX(RecurringMonths) 
FROM Staging..LineItemDiscount LE 
     JOIN Staging..LineItem L ON LE.LineItemID=L.LineItemID
                                          WHERE ContractID=@CONTRACTID
----- Calcualte Complex Stubs---------------------------------------------

DECLARE @CmplxStub table (StubStart int, StubEnd int, DayDiff int, StubFraction Numeric(18,4), R int)
DECLARE @TotalStubFractions numeric(18,4)
DECLARE @TotalStubPeriods int
DECLARE @FinalStubFraction numeric(18,4)

INSERT @CmplxStub (StubStart, StubEnd, DayDiff , StubFraction , R )
SELECT 
DAY(BillingStartDate) AS StubStart, 
MAX(DAY(EOMONTH(CurrentTermStartDate))) StubEnd,
(MAX(DAY(EOMONTH(CurrentTermStartDate)))- DAY(BillingStartDate))+1 as DayDiff ,
CONVERT(numeric(18,4), (MAX(DAY(EOMONTH(CurrentTermStartDate)))- DAY(BillingStartDate))+1) / 
CONVERT(numeric(18,4),MAX(DAY(EOMONTH(CurrentTermStartDate))))
 as StubFraction,
COUNT(*) 
FROM Staging..LineItem 
WHERE ContractID=@CONTRACTID and OriginalMonthlyPrice>1
GROUP BY BillingStartDate

SELECT @TotalStubFractions=SUM(StubFraction) from @CmplxStub;
SELECT @TotalStubPeriods=CASE WHEN ((COUNT(*)=0) OR (COUNT(*) IS NULL)) THEN 1 ELSE COUNT(*) END  from @CmplxStub ;

IF @TotalStubPeriods > 0 BEGIN 
SELECT @FinalStubFraction = @TotalStubFractions / @TotalStubPeriods END;

IF @TotalStubPeriods > 1 BEGIN SET @STUB_FRACTION=@FinalStubFraction END;

--SELECT @FinalStubFraction FinalStubFraction
--SELECT @TotalStubFractions TotalStubFractions
--SELECT @TotalStubPeriods TotalStubPeriods

---------------------------- Monetary Calcualtions Start Below -------------
--------------------- Step 1. calculate the initial amount (contract value before Discounts ) 
SELECT @CONTRACT_REG_MTH_AMT=SUM(ISNULL(CurrentMonthlyPrice,0))
FROM Staging..LineItem  WHERE ContractID=@CONTRACTID

--------------------- Step2 calculate the Discount amount (value of Dicounts )

DECLARE @CONTRACT_DSC1 TABLE (DSC_MTH1 INT,CONTRACT_TRM1 INT,DSC_TERM1 INT,DSC_AMT1 MONEY,TOTAL_DSC_AMT1 MONEY)
DECLARE @DSC_MTH1 INT, @CONTRACT_TRM1 INT=36,@DSC_TERM1 INT,@DSC_AMT1 MONEY ,@TOTAL_DSC_AMT1 MONEY
DECLARE @GRAND_TOTAL_DSC_AMT MONEY
DECLARE @DSC_NUMBR_IN_THIS_CONTRACT INT
-------------------------------- HANDLE MULTI-ESCALATION CONTRACTS ---------------------
INSERT INTO @CONTRACT_DSC1 (DSC_MTH1,CONTRACT_TRM1,DSC_TERM1,DSC_AMT1,TOTAL_DSC_AMT1)
SELECT 
LID.DiscountMonth AS DSC_MTH1,
@CURRENT_TERM AS CONTRACT_TERM1,
((@CURRENT_TERM-CONVERT(INT,LID.DiscountMonth))+2) AS DSC_TERM1,
SUM(LI.EffectiveDiscountAmount) AS  DSC_AMT1,
SUM(LI.EffectiveDiscountAmount)*((@CURRENT_TERM-CONVERT(INT,LID.DiscountMonth))+2)  AS TOTAL_DSC_AMT1
FROM 
Staging..LineItem LI 
JOIN Staging..LineItemDiscount LID 
ON LI.LineItemID=LID.LineItemID 
WHERE LI.ContractID =@CONTRACTID 
GROUP BY LID.DiscountMonth

SELECT @GRAND_TOTAL_DSC_AMT=SUM(TOTAL_DSC_AMT1) FROM @CONTRACT_DSC1;
SELECT @DSC_NUMBR_IN_THIS_CONTRACT=COUNT(*) FROM @CONTRACT_DSC1;

IF @DSC_NUMBR_IN_THIS_CONTRACT = 1

BEGIN
SELECT @CONTRACT_DSC_MTH_AMT=SUM(ISNULL(EffectiveDiscountAmount,0))
FROM Staging..LineItem  WHERE ContractID=@CONTRACTID
END

IF @DSC_NUMBR_IN_THIS_CONTRACT > 1

BEGIN
SET @CONTRACT_DISCOUNT_AMT = @GRAND_TOTAL_DSC_AMT;
SET @GRAND_TOTAL_STRAIGHT_AMT = @CONTRACT_REG_MTH_AMT * @CURRENT_TERM;
SET @GRAND_TOTAL_CONTRACT_AMT = @GRAND_TOTAL_STRAIGHT_AMT  - @CONTRACT_DISCOUNT_AMT;
END

IF @DSC_NUMBR_IN_THIS_CONTRACT = 0
BEGIN
SET @CONTRACT_DSC_MTH_AMT = 0
END


IF @DISCOUNT_MTH_START < @CURRENT_TERM AND @CONTRACT_DSC_MTH_AMT > 0
  BEGIN    SET @STRAIGHT_LINE_CONTRACT_FLG=1  END 

SET @TRUE_INI_PRD=(@CURRENT_TERM-@TRUE_DSC_PRD) + 1
SET @CONTRACT_INITAL_AMT=@CONTRACT_REG_MTH_AMT * @TRUE_INI_PRD

SET @TRUE_TERM=CAST(@CURRENT_TERM AS NUMERIC(18,4)) + CAST(@STUB_FRACTION AS NUMERIC(18,4))
SET @WATERFALL_AMT = @CONTRACT_INITAL_AMT / @TRUE_TERM
SET @WATERFALL_STUB_AMT = @WATERFALL_AMT * @STUB_FRACTION

SET @GRAND_TOTAL_CONTRACT_FINAL_AMT = @GRAND_TOTAL_CONTRACT_AMT + @STUB_AMT
SET @GRAND_WATERFALL_AMT = @GRAND_TOTAL_CONTRACT_FINAL_AMT / @TRUE_TERM
SET @GRAND_WATERFALL_STUB_AMT = @GRAND_WATERFALL_AMT * @STUB_FRACTION

--------------------------------------------------------
----------- DISPLAY INTERM RESULTS --------------------
--SELECT @CONTRACTID CONTRACTID
--SELECT @CURRENT_TERM CURRENT_TERM;
--SELECT @RENEWALS RENEWALS
--SELECT @CONTRACT_FINAL_AMT CONTRACT_FINAL_AMT
--SELECT @CONTRACT_DISCOUNT_AMT CONTRACT_DISCOUNT_AMT
--SELECT @CONTRACT_DSC_MTH_AMT CONTRACT_DSC_MTH_AMT
--SELECT @DISCOUNT_MTH_START DISCOUNT_MTH_START
--SELECT @CONTRACT_INITAL_AMT CONTRACT_INITAL_AMT
--SELECT @CONTRACT_REG_MTH_AMT CONTRACT_REG_MTH_AMT
--SELECT @TRUE_TERM TRUE_TERM 
--SELECT @STUB_AMT STUB_AMT
--SELECT @STUB_FRACTION STUB_FRACTION
--SELECT @STUB_DIFF_DAYS STUB_DIFF_DAYS
--SELECT @STUB_START STUB_START
--SELECT @STUB_END STUB_END
--SELECT @STUB_START_DAY STUB_START_DAY
--SELECT @STUB_MTH_TOTAL_DAYS STUB_MTH_TOTAL_DAYS
--SELECT @WATERFALL_AMT WATERFALL_AMT
--SELECT @WATERFALL_STUB_AMT WATERFALL_STUB_AMT
--SELECT @STRAIGHT_LINE_CONTRACT_FLG STRAIGHT_LINE_CONTRACT_FLG
--SELECT @DSC_NUMBR_IN_THIS_CONTRACT DSC_NUMBR_IN_THIS_CONTRACT
--SELECT @GRAND_TOTAL_DSC_AMT GRAND_TOTAL_DSC_AMT
--SELECT @GRAND_TOTAL_CONTRACT_AMT GRAND_TOTAL_CONTRACT_AMT
--SELECT @GRAND_TOTAL_CONTRACT_FINAL_AMT GRAND_TOTAL_CONTRACT_FINAL_AMT
--SELECT @GRAND_WATERFALL_AMT GRAND_WATERFALL_AMT
--SELECT @GRAND_WATERFALL_STUB_AMT GRAND_WATERFALL_STUB_AMT
-------------------------------------------------------
---- Perform final Insert of the Results for that Contract

IF (@DSC_NUMBR_IN_THIS_CONTRACT = 1 OR @DSC_NUMBR_IN_THIS_CONTRACT = 0) AND ( @CONTRACT_STRLN_PROCESSED = 0 )
                                                                                                              --AND ( @RENEWALS = 1 )

BEGIN

INSERT stg.StraightLineDiscountContracts (
[ContractID],
[Waterfall_Amt],
[Waterfall_Stub_Amt],
[Contract_Final_Amt],
StraightLine_Flg,
Cnt
)
SELECT 
@CONTRACTID,
@WATERFALL_AMT,
@WATERFALL_STUB_AMT,
@CONTRACT_INITAL_AMT,
@STRAIGHT_LINE_CONTRACT_FLG,
@DSC_NUMBR_IN_THIS_CONTRACT

--------------------------------------
--- now merge--- with main container 
--------------------------------------
MERGE INTO [dbo].StraightLineDiscountContracts TGT
	 USING 
	 (SELECT 
	   [ContractID]
      ,[Waterfall_Amt]
      ,[Waterfall_Stub_Amt]
      ,[Contract_Final_Amt]
      ,[StraightLine_Flg]
      ,[Cnt]
	 FROM  [stg].StraightLineDiscountContracts

			)  SRC

	 ON
TGT.[ContractID]=SRC.[ContractID] AND
TGT.[Waterfall_Amt]=SRC.[Waterfall_Amt] AND
TGT.[Waterfall_Stub_Amt]=SRC.[Waterfall_Stub_Amt] AND
TGT.[Contract_Final_Amt]=SRC.[Contract_Final_Amt] AND
TGT.[StraightLine_Flg]=SRC.[StraightLine_Flg]
WHEN MATCHED THEN 
UPDATE SET 
TGT.[ContractID]=SRC.[ContractID],
TGT.[Waterfall_Amt]=SRC.[Waterfall_Amt],
TGT.[Waterfall_Stub_Amt]=SRC.[Waterfall_Stub_Amt],
TGT.[Contract_Final_Amt]=SRC.[Contract_Final_Amt],
TGT.[StraightLine_Flg]=SRC.[StraightLine_Flg]
WHEN NOT MATCHED THEN
INSERT 
(
       [ContractID]
      ,[Waterfall_Amt]
      ,[Waterfall_Stub_Amt]
      ,[Contract_Final_Amt]
      ,[StraightLine_Flg]
      ,[Cnt]
)

VALUES( 

       SRC.[ContractID]
      ,SRC.[Waterfall_Amt]
      ,SRC.[Waterfall_Stub_Amt]
      ,SRC.[Contract_Final_Amt]
      ,SRC.[StraightLine_Flg]
      ,SRC.[Cnt]
);



END

IF ( @DSC_NUMBR_IN_THIS_CONTRACT > 1 ) AND ( @CONTRACT_STRLN_PROCESSED = 0 ) 
                                                                             --AND ( @RENEWALS = 1 )

BEGIN

INSERT stg.StraightLineDiscountContracts (
[ContractID],
[Waterfall_Amt],
[Waterfall_Stub_Amt],
[Contract_Final_Amt],
StraightLine_Flg,
Cnt
)
SELECT 
@CONTRACTID,
@GRAND_WATERFALL_AMT,
@GRAND_WATERFALL_STUB_AMT,
@GRAND_TOTAL_CONTRACT_FINAL_AMT,
@STRAIGHT_LINE_CONTRACT_FLG,
@DSC_NUMBR_IN_THIS_CONTRACT


--------------------------------------
--- now merge--- with main container 
--------------------------------------
MERGE INTO [dbo].StraightLineDiscountContracts TGT
	 USING 
	 (SELECT 
	   [ContractID]
      ,[Waterfall_Amt]
      ,[Waterfall_Stub_Amt]
      ,[Contract_Final_Amt]
      ,[StraightLine_Flg]
      ,[Cnt]
	 FROM  [stg].StraightLineDiscountContracts

			)  SRC

	 ON
TGT.[ContractID]=SRC.[ContractID] AND
TGT.[Waterfall_Amt]=SRC.[Waterfall_Amt] AND
TGT.[Waterfall_Stub_Amt]=SRC.[Waterfall_Stub_Amt] AND
TGT.[Contract_Final_Amt]=SRC.[Contract_Final_Amt] AND
TGT.[StraightLine_Flg]=SRC.[StraightLine_Flg]
WHEN MATCHED THEN 
UPDATE SET 
TGT.[ContractID]=SRC.[ContractID],
TGT.[Waterfall_Amt]=SRC.[Waterfall_Amt],
TGT.[Waterfall_Stub_Amt]=SRC.[Waterfall_Stub_Amt],
TGT.[Contract_Final_Amt]=SRC.[Contract_Final_Amt],
TGT.[StraightLine_Flg]=SRC.[StraightLine_Flg]
WHEN NOT MATCHED THEN
INSERT 
(
       [ContractID]
      ,[Waterfall_Amt]
      ,[Waterfall_Stub_Amt]
      ,[Contract_Final_Amt]
      ,[StraightLine_Flg]
      ,[Cnt]
)

VALUES( 

       SRC.[ContractID]
      ,SRC.[Waterfall_Amt]
      ,SRC.[Waterfall_Stub_Amt]
      ,SRC.[Contract_Final_Amt]
      ,SRC.[StraightLine_Flg]
      ,SRC.[Cnt]
);



END

END TRY


BEGIN CATCH
         -------------ERROR HANDLING AREA---------------------------------------------------------------------------------------
		 DECLARE @ERROR_MSG VARCHAR(8000)
		 SET @ERROR_MSG = ERROR_MESSAGE()
		 SET @VARIABLE_VALUES = 'ContractID: ' + CAST(@CONTRACTID AS VARCHAR(20)) + ' / Discount Type:' + CASE @DSC_NUMBR_IN_THIS_CONTRACT WHEN 1 THEN ' Simple ' 
		                                                                                                                                    WHEN 0 THEN 'No Discount'
																																            ELSE 'Complex Discount' END 
		 INSERT [dbo].[SkuError] ([ProcedureName],[ProcessingLogicUsed],[ErrorMessage],[VariableValues],[AuditDate])
		 SELECT @PROCEDURE_NAME,'Discount Waterfall', @ERROR_MSG, @VARIABLE_VALUES, GETDATE()
         ---------------------------------------------------------------------------------------------------------------------
END CATCH







GO
