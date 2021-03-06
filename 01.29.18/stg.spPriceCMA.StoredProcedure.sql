USE [RevPro]
GO
/****** Object:  StoredProcedure [stg].[spPriceCMA]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [stg].[spPriceCMA]
	
	@pNoPropertyMarketCount        int=0,
	@pRetailSqFt int,
	@pIndustrialSqFt int,
	@pOfficeSqFt int,
	@pMFCount int,
	@pProductID int
	, @pDebug bit = 0
AS
	
	declare @TotalUnitRounded  int   =0
	Declare @PricePerMonth     Money =0 

	declare @RateBasis        float =0
	Declare  @RateBasisText Varchar(20)
	declare @cmaPrice money
	Declare  @SKU Varchar(20)='C'

	if object_id('tempdb..#tmpfinal') is not null drop table #tmpfinal;   


set @RateBasis = (@pIndustrialSqFt/4000)+(@pRetailSqFt/2000)+(@pOfficeSqFt/1000)+sum(@pMFCount);


select @TotalUnitRounded=500*Ceiling(@RateBasis/500) 

IF @TotalUnitRounded IS NULL
    SET @TotalUnitRounded=500
    
IF @TotalUnitRounded=500
   SELECT @PricePerMonth=850

IF @TotalUnitRounded=1000
   SELECT @PricePerMonth=1500

IF  @TotalUnitRounded>1000 AND @TotalUnitRounded<=10000
    SELECT @PricePerMonth=1500+(@TotalUnitRounded-1000)/2

IF  @TotalUnitRounded>10000
    SELECT @PricePerMonth=@TotalUnitRounded*0.6

SELECT @RateBasisText=Cast(@TotalUnitRounded AS VARCHAR(10))

set  @RateBasisText=right('0000'+@RateBasisText,4)
	

SELECT @cmaPrice=CEILING(ROUND(@PricePerMonth,2))


 IF @pNoPropertyMarketCount =0
  BEGIN
    SET    @SKU='C'
    SET    @SKU=@SKU+@RateBasisText+'RE'+Cast(@pNoPropertyMarketCount as varchar(4))
    SELECT @pProductID ProductID,--@pBillingMonth BillingMonth,
	@SKU SKU,(@cmaPrice) AS Price, 'Region Market' AS "Description"
  END

if @pNoPropertyMarketCount =1
  BEGIN
   SET    @SKU='C'
   SET    @SKU=@SKU+@RateBasisText+'RE'+Cast(@pNoPropertyMarketCount as varchar(4))
   SELECT @pProductID ProductID,--@pBillingMonth BillingMonth,
   @SKU SKU,(@cmaPrice+395) as Price, 'Region+ 1 Market' as "Description"
  END


if @pNoPropertyMarketCount=2
  BEGIN
   SET    @SKU='C'
   SET    @SKU=@SKU+@RateBasisText+'RE'+Cast(@pNoPropertyMarketCount as varchar(4))
   SELECT @pProductID ProductID,--@pBillingMonth BillingMonth, 
   @SKU SKU,(@cmaPrice+691) as Price, 'Region+ 2 Market' as  "Description"
  END
 
if @pNoPropertyMarketCount=3
  BEGIN
    SET @SKU='C'
	SET  @SKU=@SKU+@RateBasisText+'RE'+Cast(@pNoPropertyMarketCount as varchar(4))
    SELECT @pProductID ProductID,--@pBillingMonth BillingMonth,
	@SKU SKU, (@cmaPrice+988) as Price,'Region+ 3 Market' as "Description"
  END

if @pNoPropertyMarketCount >3
  BEGIN
   SET @SKU=@SKU+@RateBasisText+'NA0'--+Cast(@NoProperty as varchar(4)) 
   SELECT @pProductID ProductID,--@pBillingMonth BillingMonth,
   @SKU SKU,(@cmaPrice+1295) as Price,'Region+ 1 National' as "Description"
  END

RETURN 0

GO
