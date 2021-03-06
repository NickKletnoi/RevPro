USE [RevPro]
GO
/****** Object:  UserDefinedFunction [stg].[fnProrateMonthlyAmount]    Script Date: 1/29/2018 3:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [stg].[fnProrateMonthlyAmount] 
( 
    @Month datetime,            -- month for which the proration will be calculated 
    @DurationStart datetime,    -- start date of the proration duration 
    @DurationEnd datetime,      -- end date of the proration duration 
    @MonthlyAmount [decimal](38, 20)       --monthly amount to be prorated 
 )

RETURNS @RtnValue table 
( 
    TotalDays int,             -- total days in month 
    TotalAmount [decimal](38, 20),         -- total monthly amount 
    ProratedDays int,          --— number of prorated days 
    AmountPerDay [decimal](38, 20),        --dollar amount per day 
    ProratedAmount [decimal](38, 20)       -- prorated dollar amount 
) 
AS  
BEGIN

    --— declare variables 
    DECLARE @MonthEnd datetime 
    DECLARE @TotalDays int, @ProratedDays int 
    DECLARE @HoursPerDay [decimal](38, 20), @ProratedHours [decimal](38, 20) 
    DECLARE @AmountPerDay [decimal](38, 20), @ProratedAmount [decimal](38, 20) 
    
    -- initialize variables 
    SET @Month = DATEADD(DAY, -(DATEPART(DAY, @Month)-1), @Month)    
    SET @MonthEnd = DATEADD(DAY, -1, DATEADD(MONTH, 1, @Month)) 
    SET @TotalDays = DATEPART(dd, @MonthEnd) 
    SET @ProratedDays = DATEDIFF(DAY, @DurationStart, @DurationEnd) + 1 
    SET @AmountPerDay = @MonthlyAmount/@TotalDays
    SET @ProratedAmount = @MonthlyAmount 
  
    IF @TotalDays > @ProratedDays 
         SET @ProratedAmount = @ProratedDays * @AmountPerDay 
   
       
    -- return results 
    INSERT INTO @RtnValue 
    ( 
        TotalDays, 
        TotalAmount, 
        ProratedDays, 
        AmountPerDay, 
        ProratedAmount 
    ) 
    SELECT     
        @TotalDays, 
        @MonthlyAmount, 
        @ProratedDays, 
        @AmountPerDay, 
        @ProratedAmount 
    
    Return 
END



GO
