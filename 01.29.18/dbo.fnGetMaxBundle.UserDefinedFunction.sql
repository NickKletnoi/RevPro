USE [RevPro]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetMaxBundle]    Script Date: 1/29/2018 3:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fnGetMaxBundle](@ContractID INT)  
RETURNS INT    
AS   
-- Returns max BundleID having the same term month/year as the missing bundle inside of the contract  
BEGIN  
DECLARE @YEAR_MNTH VARCHAR(6);    
DECLARE @BundleID INT;

SELECT @YEAR_MNTH=CAST(YEAR(MAX(L.LineItemStatusDate)) AS char(4)) + CAST(MONTH(MAX(L.LineItemStatusDate)) AS char(2))
FROM Staging..LineItem L WHERE L.ContractID=@ContractID AND L.BundleID IS NOT NULL;
 
SELECT @BundleID=MAX(A.BundleID)  
    FROM 
	( SELECT BundleID, CAST(YEAR(L.LineItemStatusDate) AS char(4)) + CAST(MONTH(L.LineItemStatusDate) AS char(2)) as LineItemStatusYearMonth
	  FROM Staging..LineItem L JOIN 
		( SELECT distinct 
		
	CAST(YEAR(L2.LineItemStatusDate) AS char(4)) + CAST(MONTH(L2.LineItemStatusDate) AS char(2)) AS LineItemStatusYearMonth 
		
		from Staging..LineItem L2 
						where ContractID=@ContractID and L2.BundleID IS NULL
		                ) b ON 
						CAST(YEAR(L.LineItemStatusDate) AS char(4)) + CAST(MONTH(L.LineItemStatusDate) AS char(2))
						=b.LineItemStatusYearMonth

	  WHERE L.ContractID=@ContractID AND L.BundleID IS NOT NULL
	  ) A
	  
  RETURN @BundleID;  
END;  


 


GO
