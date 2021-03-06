USE [RevPro]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetAccountingFirstDayFromPeriod]    Script Date: 1/29/2018 3:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnGetAccountingFirstDayFromPeriod](@d varchar(10))  
RETURNS DATE
AS   

BEGIN  

   DECLARE @v DATE

SELECT @v=CONVERT(DATE,RP.AccountingStartDate) FROM Staging.rcl.Reconciliation_Period RP WHERE RP.ReconciliationPeriod=@d

	RETURN @v
END;  


GO
