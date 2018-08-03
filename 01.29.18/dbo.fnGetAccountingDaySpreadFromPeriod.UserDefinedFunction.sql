USE [RevPro]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetAccountingDaySpreadFromPeriod]    Script Date: 1/29/2018 3:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnGetAccountingDaySpreadFromPeriod](@d varchar(10))  
RETURNS INT
AS   

BEGIN  

   DECLARE @v INT

SELECT @v=RP.AccountingDaySpread 
FROM Staging.rcl.Reconciliation_Period RP 
WHERE RP.ReconciliationPeriod=@d

	RETURN @v
END;  



GO
