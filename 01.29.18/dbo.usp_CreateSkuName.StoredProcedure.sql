USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreateSkuName]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[usp_CreateSkuName](@SKUID INT)  
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
----- interogate the Sku in terms of product------------------------------------------------------
SELECT @SUITE_CNT=COUNT(*) FROM tst.Sku WHERE SKUID=@SKUID AND ProductID IN (1,2,5); 
SELECT @COMBO_CNT=COUNT(*) FROM tst.Sku WHERE SKUID=@SKUID AND ((ProductID IN (1,5)) OR (ProductID IN (1,2)) OR (ProductID IN (2,5)));
SELECT @SINGLE_CNT=COUNT(*) FROM tst.Sku WHERE SKUID=@SKUID HAVING COUNT(*)=1;
SELECT @ITEM_CNT=COUNT(*) FROM tst.Sku WHERE SKUID=@SKUID;

IF (@SUITE_CNT IS NULL) AND (@COMBO_CNT IS NULL) AND (@SINGLE_CNT IS NULL) BEGIN SET @OTHER_CNT=1 END;

SELECT @SUITE_CNT SUITE_CNT;
SELECT @COMBO_CNT COMBO_CNT;
SELECT @SINGLE_CNT SINGLE_CNT;
SELECT @ITEM_CNT ITEM_CNT;


IF ( (@SUITE_CNT >= 3 OR @COMBO_CNT = 3) AND @SINGLE_CNT IS NULL) 


BEGIN ------------  THIS IS THE STANDARD SUITE NAME ASSEMBLY ------------------------
SELECT @SKU_NAME=
CAST(SKUID AS VARCHAR(20)) +'-Suite-'+ CAST(
(SELECT TOP 1 M.MarketName from tst.Sku S2 JOIN dbo.Market M ON S2.MarketID=M.MarketID
 where S2.SKUID=S1.SKUID) AS VARCHAR(200) ) +'-'+
CAST(
(SELECT TOP 1 UserCount from tst.Sku S3  
where S3.SKUID=S1.SKUID) as Varchar(200)) +'-'+
CAST(
(SELECT TOP 1 BTC.BusinessTypeCategory from tst.Sku S4 
JOIN dbo.BusinessTypeCategory BTC ON 
S4.CustomerType=BTC.BusinessTypeCategoryID
where S4.SKUID=S1.SKUID) as Varchar(200))
FROM tst.Sku S1 WHERE SKUID=@SKUID;

SELECT @SKU_NAME SKU_NAME;

END

IF ( (@SUITE_CNT = 1) AND (@ITEM_CNT > 2))

BEGIN
SELECT @SKU_NAME=
CAST(S11.SKUID AS VARCHAR(20)) +'-' + COALESCE (P.ProductDesc,'N/A') + '-'+ CAST(
(SELECT TOP 1 COALESCE (M.MarketName,'N/A') 
FROM tst.Sku S2 JOIN dbo.Market M ON S2.MarketID=M.MarketID
 where S2.SKUID=S11.SKUID) AS VARCHAR(200)) +'-'+
CAST(
(SELECT TOP 1 COALESCE (UserCount,0) FROM tst.Sku S3  
WHERE S3.SKUID=S11.SKUID) as Varchar(200))
FROM tst.Sku S11 JOIN Staging..Product P 
ON S11.ProductID=P.ProductID
AND S11.SKUID=@SKUID;

SELECT @SKU_NAME SKU_NAME;

END
--IF (@COMBO_CNT >= 2 AND @SUITE_CNT >=3) 

--BEGIN ------------  TREAT THIS AS A SUITE PRODUCT ------------------------
--SELECT @SKU_NAME=
--CAST(SKUID AS VARCHAR(20)) +'-Suite-'+ CAST(
--(SELECT TOP 1 M.MarketName from tst.Sku S2 JOIN dbo.Market M ON S2.MarketID=M.MarketID
-- where S2.SKUID=S1.SKUID) AS VARCHAR(100) ) +'-'+
--CAST(
--(SELECT TOP 1 UserCount from tst.Sku S3  
--where S3.SKUID=S1.SKUID) as Varchar(100)) +'-'+
--CAST(
--(SELECT TOP 1 BTC.BusinessTypeCategory from tst.Sku S4 
--JOIN dbo.BusinessTypeCategory BTC ON 
--S4.CustomerType=BTC.BusinessTypeCategoryID
--where S4.SKUID=S1.SKUID) as Varchar(100))
--FROM tst.Sku S1;
--END

--IF ((@SINGLE_CNT > 0) AND (@SUITE_CNT < 3) AND (@COMBO_CNT < 2) ) 

--BEGIN ------------  TREAT THIS AS A SINGLE PRODUCT ------------------------
--SELECT @SKU_NAME=
--CAST(SKUID AS VARCHAR(20)) +'-' + P.ProductDesc + '-'+ CAST(
--(SELECT TOP 1 M.MarketName from tst.Sku S2 JOIN dbo.Market M ON S2.MarketID=M.MarketID
-- where S2.SKUID=S1.SKUID) AS VARCHAR(100) ) +'-'+
--CAST(
--(SELECT TOP 1 UserCount from tst.Sku S3  
--where S3.SKUID=S1.SKUID) as Varchar(100)) +'-'+
--CAST(
--(SELECT TOP 1 BTC.BusinessTypeCategory from tst.Sku S4 
--JOIN dbo.BusinessTypeCategory BTC ON 
--S4.CustomerType=BTC.BusinessTypeCategoryID
--where S4.SKUID=S1.SKUID) as Varchar(100))
--FROM tst.Sku S1 JOIN Staging..Product P ON S1.ProductID=P.ProductID;
--END

--IF ((@OTHER_CNT = 1)) 

--BEGIN ------------  this is the basic Exception scenario ------------------------
--SELECT @SKU_NAME=
--CAST(SKUID AS VARCHAR(20)) +'-AddOn:'+ P.ProductDesc + CAST(
--(SELECT TOP 1 M.MarketName from tst.Sku S2 JOIN dbo.Market M ON S2.MarketID=M.MarketID
-- where S2.SKUID=S1.SKUID) AS VARCHAR(100) ) +'-'+
--CAST(
--(SELECT TOP 1 UserCount from tst.Sku S3  
--where S3.SKUID=S1.SKUID) as Varchar(100)) +'-'+
--CAST(
--(SELECT TOP 1 BTC.BusinessTypeCategory from tst.Sku S4 
--JOIN dbo.BusinessTypeCategory BTC ON 
--S4.CustomerType=BTC.BusinessTypeCategoryID
--where S4.SKUID=S1.SKUID) as Varchar(100))
--FROM tst.Sku S1 JOIN Staging..Product P ON S1.ProductID=P.ProductID;
--END

--------------------------------------------------------------------------------------------------	  
--RETURN @SKU_NAME;  

END;  


GO
