USE [RevPro]
GO
/****** Object:  UserDefinedFunction [dbo].[fnCreateSkuName]    Script Date: 1/29/2018 3:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[fnCreateSkuName](@SKUID INT)  
RETURNS VARCHAR(1000)
AS   
-- Assembles and returns the SkuName given the SKUID   
BEGIN  
---- initiate holders for all possible product scenarios
DECLARE @SKU_NAME VARCHAR(1000);
DECLARE @SUITE_CNT INT;    
DECLARE @COMBO_CNT INT;
DECLARE @SINGLE_CNT INT;
DECLARE @OTHER_CNT INT;
DECLARE @ITEM_CNT INT;
DECLARE @SUITE_TAG VARCHAR(20)='-Suite-'
DECLARE @COMBO_TAG VARCHAR(20)='-Combo-'
DECLARE @DSH CHAR(1)='-'
DECLARE @NA CHAR(3)='N/A'

----- interogate the Sku in terms of product------------------------------------------------------
SELECT @SUITE_CNT=COUNT(*) FROM dbo.Sku WHERE SKUID=@SKUID AND ProductID IN (1,2,5); 
SELECT @COMBO_CNT=COUNT(*) FROM dbo.Sku WHERE SKUID=@SKUID AND ((ProductID IN (1,5)) OR (ProductID IN (1,2)) OR (ProductID IN (2,5)));
SELECT @SINGLE_CNT=COUNT(*) FROM dbo.Sku WHERE SKUID=@SKUID HAVING COUNT(*)=1;
SELECT @ITEM_CNT=COUNT(*) FROM dbo.Sku WHERE SKUID=@SKUID;

IF (@SUITE_CNT IS NULL) AND (@COMBO_CNT IS NULL) AND (@SINGLE_CNT IS NULL) BEGIN SET @OTHER_CNT=1 END;

IF ( (@SUITE_CNT >= 3 OR @COMBO_CNT = 3) AND @SINGLE_CNT IS NULL) 

BEGIN ------------  THIS IS THE STANDARD SUITE SKU NAME ASSEMBLY ------------------------

SELECT @SKU_NAME=

CAST(SKUID AS VARCHAR(20)) + @SUITE_TAG + 

CAST(
		(SELECT TOP 1 M.MarketName FROM dbo.Sku S2 JOIN dbo.Market M 
				ON S2.MarketID=M.MarketID
					WHERE S2.SKUID=S1.SKUID) AS VARCHAR(200) ) + @DSH +
CAST(
		(SELECT TOP 1 UserCount FROM dbo.Sku S3  
					WHERE S3.SKUID=S1.SKUID) as Varchar(200)) + @DSH +
CAST(
		(SELECT TOP 1 BTC.BusinessTypeCategory FROM dbo.Sku S4 
			JOIN dbo.BusinessTypeCategory BTC ON 
				S4.CustomerType=BTC.BusinessTypeCategoryID
					WHERE S4.SKUID=S1.SKUID) as Varchar(200))

FROM dbo.Sku S1 WHERE SKUID=@SKUID AND SkuName IS NULL;

END

IF ( (@SUITE_CNT = 1) AND (@ITEM_CNT > 2) )

BEGIN  ------------  THIS IS THE NON-STANDARD SKU NAME ASSEMBLY ------------------------

SELECT @SKU_NAME=
CAST(S11.SKUID AS VARCHAR(20)) + @DSH + COALESCE (P.ProductDesc,@NA) + @DSH + CAST(
		(SELECT TOP 1 COALESCE (M.MarketName,@NA) 
				FROM dbo.Sku S2 JOIN dbo.Market M ON S2.MarketID=M.MarketID
						WHERE S2.SKUID=S11.SKUID) AS VARCHAR(200)) + @DSH +
CAST(
		(SELECT TOP 1 COALESCE (UserCount,0) FROM dbo.Sku S3  
						WHERE S3.SKUID=S11.SKUID) as Varchar(200))
FROM dbo.Sku S11 JOIN Staging..Product P 
ON S11.ProductID=P.ProductID
AND S11.SKUID=@SKUID  AND S11.SkuName IS NULL;;

END

RETURN @SKU_NAME;  

END;  



GO
