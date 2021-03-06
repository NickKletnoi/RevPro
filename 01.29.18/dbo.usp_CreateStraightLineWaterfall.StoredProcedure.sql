USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreateStraightLineWaterfall]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
truncate table dbo.StraightLineContracts
drop table dbo.StraightLineContracts

-------------------------------------------------
EXEC  [dbo].[usp_CreateStraightLineWaterfall] 187369
EXEC  [dbo].[usp_CreateStraightLineWaterfall] 175582
---------------------------------------------------

*/

CREATE PROC [dbo].[usp_CreateStraightLineWaterfall]
@CONTRACTID INT=175582
AS

BEGIN TRY

---- Error handling
DECLARE @PROCEDURE_NAME Varchar(150)='usp_CreateStraightLineWaterfall'
DECLARE @VARIABLE_VALUES Varchar(8000)
------  Declare Period vars
DECLARE @CURRENT_TERM INT
DECLARE @RENEWALS INT
DECLARE @ESCALATION_MTH_START INT
DECLARE @TRUE_INI_PRD INT
DECLARE @TRUE_INI_PRD_ADJ INT
DECLARE @TRUE_ESC_PRD INT
DECLARE @TRUE_ESC_PRD_ADJ INT
DECLARE @TRUE_TERM NUMERIC(18,4)
------- Declare flags vars
DECLARE @STRAIGHT_LINE_CONTRACT_FLG BIT=0 
DECLARE @CONTRACT_STRLN_PROCESSED INT
DECLARE @STUB_INVOLVED_FLG BIT
------ Declare money vars
DECLARE @CONTRACT_INITAL_AMT MONEY
DECLARE @CONTRACT_FINAL_AMT MONEY
DECLARE @CONTRACT_ESCALATION_AMT MONEY
DECLARE @CONTRACT_FINAL_MTH_AMT MONEY
DECLARE @CONTRACT_REG_MTH_AMT MONEY
DECLARE @CONTRACT_ESC_MTH_AMT MONEY 
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
DECLARE @GRAND_TOTAL_CONTRACT_AMT MONEY
DECLARE @GRAND_TOTAL_STRAIGHT_AMT MONEY
DECLARE @GRAND_WATERFALL_AMT MONEY
DECLARE @GRAND_WATERFALL_STUB_AMT MONEY
DECLARE @GRAND_TOTAL_CONTRACT_FINAL_AMT MONEY
----------------------------------------------
--- clear temp container---------------------

TRUNCATE TABLE stg.[StraightLineContracts]

--------------------------  Period calculations start below ---------------

SELECT @CURRENT_TERM=DATEDIFF(mm,MAX(CurrentTermStartDate),MAX(RenewalDate)) FROM Staging..LineItem  WHERE ContractID=@CONTRACTID;
SELECT @CONTRACT_STRLN_PROCESSED=COUNT(*) FROM vwStraightLineContracts WHERE ContractID=@CONTRACTID;
SELECT @RENEWALS=COUNT(DISTINCT RenewalDate) from Staging..LineItem WHERE ContractID=@CONTRACTID AND RenewalDate IS NOT NULL;

------ Calcualte easy Stubs: ---------------------

SELECT @STUB_START=MAX(CurrentTermStartDate)  FROM Staging..LineItem  WHERE ContractID=@CONTRACTID;
SELECT @STUB_END=MAX(EOMONTH(CurrentTermStartDate)) FROM Staging..LineItem  WHERE ContractID=@CONTRACTID;
SELECT @STUB_MTH_TOTAL_DAYS=DAY(@STUB_END)
SELECT @STUB_START_DAY=DAY(@STUB_START)
SELECT @STUB_DIFF_DAYS=(@STUB_MTH_TOTAL_DAYS-@STUB_START_DAY)+1
SELECT @STUB_FRACTION=CAST(@STUB_DIFF_DAYS AS NUMERIC(18,4))/CAST(@STUB_MTH_TOTAL_DAYS AS NUMERIC(18,4))

SELECT @ESCALATION_MTH_START=MAX(FirstEscalationMonth) 
FROM Staging..LineItemEscalation LE 
     JOIN Staging..LineItem L ON LE.LineItemID=L.LineItemID
                                          WHERE ContractID=@CONTRACTID
IF @ESCALATION_MTH_START < @CURRENT_TERM 
  BEGIN    SET @STRAIGHT_LINE_CONTRACT_FLG=1  END

------- Calculate complex Stubs: --------------------------------

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
SELECT @TotalStubPeriods=CASE WHEN ((COUNT(*)=0) OR (COUNT(*) IS NULL)) THEN 1 ELSE COUNT(*) END  from @CmplxStub;

IF @TotalStubPeriods > 0 BEGIN 
SELECT @FinalStubFraction = @TotalStubFractions / @TotalStubPeriods END;

IF @TotalStubPeriods > 1 BEGIN SET @STUB_FRACTION=@FinalStubFraction END;

---------------------------- Monetary Calcualtions Start Below -------------
--------------------- Step 1. calculate the initial amount (contract value before escalations ) 
SELECT @CONTRACT_REG_MTH_AMT=SUM(ISNULL(DiscountedMonthlyPrice,0))
FROM Staging..LineItem  WHERE ContractID=@CONTRACTID

--------------------- Step2 calculate the escalation amount (value of escalations )
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

DECLARE @CONTRACT_ESC1 TABLE (ESC_MTH1 INT,CONTRACT_TRM1 INT,ESC_TERM1 INT,ESC_AMT1 MONEY,TOTAL_ESC_AMT1 MONEY)
DECLARE @ESC_MTH1 INT, @CONTRACT_TRM1 INT=36,@ESC_TERM1 INT,@ESC_AMT1 MONEY ,@TOTAL_ESC_AMT1 MONEY
DECLARE @GRAND_TOTAL_ESC_AMT MONEY
DECLARE @ESC_NUMBR_IN_THIS_CONTRACT INT
-------------------------------- HANDLE MULTI-ESCALATION CONTRACTS ---------------------
INSERT INTO @CONTRACT_ESC1 (ESC_MTH1,CONTRACT_TRM1,ESC_TERM1,ESC_AMT1,TOTAL_ESC_AMT1)
SELECT 
LIE.FirstEscalationMonth AS ESC_MTH1,
@CURRENT_TERM AS CONTRACT_TERM1,
((@CURRENT_TERM-CONVERT(INT,LIE.FirstEscalationMonth))+2) AS ESC_TERM1,
SUM(LIE.EscalationAmount) AS  ESC_AMT1,
SUM(LIE.EscalationAmount)*((@CURRENT_TERM-CONVERT(INT,LIE.FirstEscalationMonth))+2)  AS TOTAL_ESC_AMT1
FROM 
Staging..LineItem LI 
JOIN Staging..LineItemEscalation LIE 
ON LI.LineItemID=LIE.LineItemID 
WHERE LI.ContractID =@CONTRACTID 
GROUP BY LIE.FirstEscalationMonth

SELECT @GRAND_TOTAL_ESC_AMT=SUM(TOTAL_ESC_AMT1) FROM @CONTRACT_ESC1;
SELECT @ESC_NUMBR_IN_THIS_CONTRACT=COUNT(*) FROM @CONTRACT_ESC1;
------------------------------------------------------------------------------------

IF @ESC_NUMBR_IN_THIS_CONTRACT = 1

BEGIN
SELECT @CONTRACT_ESCALATION_AMT=SUM(ISNULL(LE.EscalationAmount,0))
FROM Staging..LineItemEscalation LE 
     JOIN Staging..LineItem L ON LE.LineItemID=L.LineItemID
                                          WHERE ContractID=@CONTRACTID
END

IF @ESC_NUMBR_IN_THIS_CONTRACT > 1 
BEGIN
SET @CONTRACT_ESCALATION_AMT = @GRAND_TOTAL_ESC_AMT;
SET @GRAND_TOTAL_STRAIGHT_AMT = @CONTRACT_REG_MTH_AMT * @CURRENT_TERM;
SET @GRAND_TOTAL_CONTRACT_AMT = @GRAND_TOTAL_STRAIGHT_AMT  + @CONTRACT_ESCALATION_AMT
END

IF @ESC_NUMBR_IN_THIS_CONTRACT = 0
BEGIN
SET @CONTRACT_ESCALATION_AMT = 0
END


SET @CONTRACT_FINAL_MTH_AMT= @CONTRACT_REG_MTH_AMT + @CONTRACT_ESCALATION_AMT
SET @CONTRACT_ESC_MTH_AMT = @CONTRACT_FINAL_MTH_AMT

----- Assemble the true Periods ----------------
SET @TRUE_INI_PRD=(@ESCALATION_MTH_START-1)
SET @TRUE_INI_PRD_ADJ = @TRUE_INI_PRD - 1
SET @TRUE_ESC_PRD=@CURRENT_TERM-@TRUE_INI_PRD
SET @TRUE_ESC_PRD_ADJ = @TRUE_ESC_PRD + 1
SET @TRUE_TERM=CAST(@CURRENT_TERM AS NUMERIC(18,4)) + CAST(@STUB_FRACTION AS NUMERIC(18,4))

---- Assemble the Initial Stub Amount ---------

SET @STUB_AMT=@CONTRACT_REG_MTH_AMT * @STUB_FRACTION

----  Assemble the true Amounts ---------------
SET @CONTRACT_INITAL_AMT= @CONTRACT_REG_MTH_AMT * @TRUE_INI_PRD_ADJ
SET @CONTRACT_ESCALATION_AMT=@CONTRACT_FINAL_MTH_AMT * @TRUE_ESC_PRD_ADJ

SET @CONTRACT_FINAL_AMT = @CONTRACT_INITAL_AMT + @CONTRACT_ESCALATION_AMT + @STUB_AMT
SET @WATERFALL_AMT = @CONTRACT_FINAL_AMT / @TRUE_TERM
SET @WATERFALL_STUB_AMT = @WATERFALL_AMT * @STUB_FRACTION

SET @GRAND_TOTAL_CONTRACT_FINAL_AMT = @GRAND_TOTAL_CONTRACT_AMT + @STUB_AMT
SET @GRAND_WATERFALL_AMT = @GRAND_TOTAL_CONTRACT_FINAL_AMT / @TRUE_TERM
SET @GRAND_WATERFALL_STUB_AMT = @GRAND_WATERFALL_AMT * @STUB_FRACTION


----------- DISPLAY INTERM RESULTS --------------------
--SELECT @CONTRACTID CONTRACTID
--SELECT @CONTRACT_STRLN_PROCESSED CONTRACT_STRLN_PROCESSED
--SELECT @CURRENT_TERM CURRENT_TERM;
--SELECT @RENEWALS RENEWALS
--SELECT @CONTRACT_FINAL_AMT CONTRACT_FINAL_AMT
--SELECT @CONTRACT_ESCALATION_AMT CONTRACT_ESCALATION_AMT
--SELECT @CONTRACT_ESC_MTH_AMT CONTRACT_ESC_MTH_AMT
--SELECT @ESCALATION_MTH_START ESCALATION_MTH_START
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
--SELECT @TRUE_INI_PRD_ADJ TRUE_INI_PRD_ADJ
--SELECT @TRUE_ESC_PRD_ADJ TRUE_ESC_PRD_ADJ
--SELECT @ESC_NUMBR_IN_THIS_CONTRACT ESC_NUMBR_IN_THIS_CONTRACT
--SELECT @GRAND_TOTAL_ESC_AMT GRAND_TOTAL_ESC_AMT
--SELECT @GRAND_TOTAL_CONTRACT_AMT GRAND_TOTAL_CONTRACT_AMT
--SELECT @GRAND_TOTAL_CONTRACT_FINAL_AMT GRAND_TOTAL_CONTRACT_FINAL_AMT
--SELECT @GRAND_WATERFALL_AMT GRAND_WATERFALL_AMT
--SELECT @GRAND_WATERFALL_STUB_AMT GRAND_WATERFALL_STUB_AMT
---------------------------------------------------------
---- Perform final Insert of the Results for that Contract

IF (@ESC_NUMBR_IN_THIS_CONTRACT = 1 OR @ESC_NUMBR_IN_THIS_CONTRACT = 0) AND ( @CONTRACT_STRLN_PROCESSED = 0 )
																										      --AND ( @RENEWALS = 1 )

BEGIN

INSERT stg.[StraightLineContracts] ([ContractID],[Waterfall_Amt],[Waterfall_Stub_Amt],[Contract_Final_Amt],StraightLine_Flg,Cnt)
SELECT @CONTRACTID,@WATERFALL_AMT,@WATERFALL_STUB_AMT,@CONTRACT_FINAL_AMT,@STRAIGHT_LINE_CONTRACT_FLG,@ESC_NUMBR_IN_THIS_CONTRACT
--------------------------------------
--- now merge--- with main container 
--------------------------------------
MERGE INTO [dbo].[StraightLineContracts] TGT
	 USING 
	 (SELECT 
	   [ContractID]
      ,[Waterfall_Amt]
      ,[Waterfall_Stub_Amt]
      ,[Contract_Final_Amt]
      ,[StraightLine_Flg]
      ,[Cnt]
	 FROM  [stg].[StraightLineContracts]

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

IF ( @ESC_NUMBR_IN_THIS_CONTRACT > 1 )  AND ( @CONTRACT_STRLN_PROCESSED = 0 )
																				 --AND ( @RENEWALS = 1 )

BEGIN

INSERT stg.[StraightLineContracts] ([ContractID],[Waterfall_Amt],[Waterfall_Stub_Amt],[Contract_Final_Amt],StraightLine_Flg,Cnt)
SELECT @CONTRACTID,@GRAND_WATERFALL_AMT,@GRAND_WATERFALL_STUB_AMT,@GRAND_TOTAL_CONTRACT_FINAL_AMT,@STRAIGHT_LINE_CONTRACT_FLG,@ESC_NUMBR_IN_THIS_CONTRACT

-------------------------------------
--- now merge--- with main container 
-------------------------------------
MERGE INTO [dbo].[StraightLineContracts] TGT
	 USING 
	 (SELECT 
	   [ContractID]
      ,[Waterfall_Amt]
      ,[Waterfall_Stub_Amt]
      ,[Contract_Final_Amt]
      ,[StraightLine_Flg]
      ,[Cnt]
	 FROM  [stg].[StraightLineContracts]

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
		 SET @VARIABLE_VALUES = 'ContractID: ' + CAST(@CONTRACTID AS VARCHAR(20)) + ' / Escalation Type:' + CASE @ESC_NUMBR_IN_THIS_CONTRACT WHEN 1 THEN ' Simple ' 
		                                                                                                                                    WHEN 0 THEN 'No Escalation'
																																            ELSE 'Complex Escalation' END 
		 INSERT [dbo].[SkuError] ([ProcedureName],[ProcessingLogicUsed],[ErrorMessage],[VariableValues],[AuditDate])
		 SELECT @PROCEDURE_NAME,'Escalation Waterfall', @ERROR_MSG, @VARIABLE_VALUES, GETDATE()
         ---------------------------------------------------------------------------------------------------------------------
END CATCH












GO
