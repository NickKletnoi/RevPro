USE [RevPro]
GO
/****** Object:  UserDefinedFunction [dbo].[fnGetVarMonth]    Script Date: 1/29/2018 3:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnGetVarMonth](@d varchar(10))  
RETURNS Varchar(10)
AS   

BEGIN  
   DECLARE @c DATE 
   DECLARE @v VARCHAR(10)
SET @c=CONVERT(DATE,@d)
SET @v = CONVERT(VARCHAR(10),UPPER(LEFT(DATENAME(MONTH,@c),3))) + CONVERT(CHAR(2), RIGHT(YEAR(@c),2)) + '.'
	 
    RETURN @v;  
END;  

GO
