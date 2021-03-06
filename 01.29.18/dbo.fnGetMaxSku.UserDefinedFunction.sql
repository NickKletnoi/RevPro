USE [RevPro]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetMaxSku]    Script Date: 1/29/2018 3:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnGetMaxSku](@ContractID INT)  
RETURNS INT   
AS   
-- Returns a Sku having the most LineItemID's for a given Contract  
/*
      SELECT  MAX(A.SKUID)
      FROM 
	 ( SELECT TOP 1 L.SKUID, COUNT(L.LineItemID) as Maxcnt
	  FROM RevPro..LineItem L 
	  WHERE L.ContractID=@ContractID 
	  AND SKUID<>-1
	  GROUP BY L.SKUID
	  ORDER BY COUNT(L.LineItemID) desc
	   ) A 

	   RETURN @Sku; 

*/


BEGIN  
    DECLARE @Sku INT;  
    SELECT  @Sku = MAX(A.SKUID)  
    FROM 
	( SELECT L.SKUID, COUNT(L.LineItemID) as Maxcnt
	  FROM RevPro..LineItem L 
	  WHERE L.ContractID=@ContractID
	  GROUP BY L.SKUID
	  ) A
	 
    RETURN @Sku;  
END;  


GO
