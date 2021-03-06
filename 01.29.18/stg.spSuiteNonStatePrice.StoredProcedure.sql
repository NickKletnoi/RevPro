USE [RevPro]
GO
/****** Object:  StoredProcedure [stg].[spSuiteNonStatePrice]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [stg].[spSuiteNonStatePrice]
(  @pLocationID INT
  ,@pContractID INT
  ,@pProductMarketTypeID tinyInt
  ,@pnumberofCounties SMALLINT=0
  ,@pnumberofMarket SMALLINT
  ,@pUserCount SMALLINT    -- =20
  ,@pProductCount SMALLINT
  ,@pTotalStaff int
  ,@pHomeStateCD char(2)
  ,@pHomeMarketId int
  ,@pIndustryTypeGroupID int
 -- ,@pBillingMonth varchar(8)
--  ,@pMEA varchar(100)
  --,@pProductID int
  ,@pDebug bit
 )
AS

-- =====================================================================================================
-- TK
-- 11/06/2015 getting market information from enterprise instead of  sls.locationviewPort   TFS#251668 
-- 11/17/2015-- Getting staff count from dbo.locationProfile instead of dbo.Contact         TFS#254134
-- =====================================================================================================
 SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	
	DECLARE @TwoMarketFactor		DECIMAL(10,2)=1.5
	DECLARE @ThreeMarketFactor		DECIMAL(10,2)=1.9
	DECLARE @MarketFactor			DECIMAL(10,2)=0.33
	DECLARE @CountyFactor			DECIMAL(10,2)=0.55
	DECLARE @MarketTier   			INT
	DECLARE @TotalStaffRangeId		TINYINT    -- 1)"1 - 15" 2)"16 - 30" 3)"31 +"
	DECLARE @VersionId				TINYINT 
	DECLARE @pProductCategoryId TINYINT =4  -- 3)2-Product 4)Suite 5)Suite + SC 6)1-Product
	DECLARE @SuitePrice				MONEY
	DECLARE @ID						INT
	DECLARE @CurrentPrice			MONEY
	--DECLARE @CountyPrice			MONEY
	DECLARE @Currentmarket			VARCHAR(30)
	DECLARE @NationalPrice			MONEY
	DECLARE @ImplementationFeePrice MONEY
	DECLARE @TotalMarketPrice       MONEY
	DECLARE @TotalCountyPrice       MONEY
	DECLARE @CountyPrice            MONEY=0
	DECLARE @SalesUnitID            INT=NULL
	DECLARE @SKU Varchar(50)
	DECLARE @ProductID              INT
  	DECLARE @CurrentUserCount   INT
	DECLARE @BusinessType       CHAR(1)
	/*
	  	 
	EXEC [stg].[spPropertyTenantPriceHistory] 
	   @pLocationID     =340691
      ,@pnumberofMarket =2
      ,@pUserCount      =2
      ,@pProductCount   =3
	  ,@pContractID     =148361
	  ,@pBillingMonth   ='201604'
      ,@pProductMarketTypeID=1
	  ,@pMEA ='201604_340691_2016'
  
	*/	
	   
	
    --Mapping the ProductID to the ProductCategory
  
   --IF (@pProductCount>1 AND @ProductID=10002)--_ --Suite
   --    SET @pProductCategoryId=4
	  -- SET @ProductID=3
   
   IF (@pProductCount=1)  --1-Product
      BEGIN
       SET @pProductCategoryId=2
	   SET @ProductID=1
     END

     IF @pProductCount=2 --AND @ProductID IN (1,2,5))  --2-Product
	  BEGIN 
       SET @pProductCategoryId=3
	   SET @ProductID=2
     END

	 IF (@pProductCount>=3)--_ --Suite
	  BEGIN
       SET @pProductCategoryId=4
	   SET @ProductID=3
	END
    
	--Getting the sales unit 
	
	 IF OBJECT_ID('Tempdb..#SalesUnit') IS NOT NULL DROP TABLE #SalesUnit

	 CREATE TABLE #SalesUnit(SalesUnitID int,researchMarketID int ,ProductMarketTypeID int ) 

    INSERT #SalesUnit(SalesUnitID,researchMarketID,ProductMarketTypeID)
	SELECT DISTINCT  pm.SalesUnitID,a.researchMarketID,su.ProductMarketTypeID
	FROM enterprisesub.dbo.Location l
	 inner join enterprisesub.dbo.Address a on l.addressid = a.addressid
	 inner join EnterpriseSub.dbo.addresssubmarket asm on asm.addressid = a.addressid
	 left join EnterpriseSub.dbo.ProductMarketSubmarket sup on sup.SubMarketID=asm.SubMarketID
	 left join  EnterpriseSub.dbo.SalesUnitProductMarket pm  on pm.ProductMarketID=sup.ProductMarketID
	 left join EnterpriseSub.dbo.SalesUnit su on su.SalesUnitID=pm.SalesUnitID
	WHERE l.LocationID=@pLocationID and su.SalesUnitID is not null and su.ProductID=1 
	UNION  
	SELECT DISTINCT  pm.SalesUnitID,a.researchMarketID,su.ProductMarketTypeID
	FROM enterprisesub.dbo.Location l
	inner join enterprisesub.dbo.Address a on l.addressid = a.addressid
	left join  EnterpriseSub.dbo.ProductMarketCounty pmc on pmc.CountyID=a.CountyID
	left join  EnterpriseSub.dbo.SalesUnitProductMarket pm  on pm.ProductMarketID=pmc.ProductMarketID
	left join EnterpriseSub.dbo.SalesUnit su on su.SalesUnitID=pm.SalesUnitID
	WHERE l.LocationID=@pLocationID and su.ProductID=1 and su.SalesUnitID is not null
	UNION
	SELECT DISTINCT  pm.SalesUnitID,a.researchMarketID,su.ProductMarketTypeID
	FROM enterprisesub.dbo.Location l
	inner join enterprisesub.dbo.Address a on l.addressid = a.addressid
	left join  EnterpriseSub.dbo.ProductMarketState pms on pms.StateCD=a.State
	left join  EnterpriseSub.dbo.SalesUnitProductMarket pm  on pm.ProductMarketID=pms.ProductMarketID
	left join EnterpriseSub.dbo.SalesUnit su on su.SalesUnitID=pm.SalesUnitID
	WHERE l.LocationID=@pLocationID and su.ProductID=1 and su.SalesUnitID is not null
	ORDER BY ProductMarketTypeID
		 
	SELECT TOP 1 @SalesUnitID=SalesUnitID
	FROM  #SalesUnit
	
	SET  @CurrentUserCount  =@pUserCount;
	  
	--Getting the lastest VersionID

	SELECT TOP 1 @VersionID=MAX(VersionId)
	FROM  EnterpriseSalesPricing.[prc].[MarketUserProductPrice] 
	WHERE CurrentPrice=1

	--Getting the Total staff count

	
	
	IF (@pTotalStaff =0)
	   SET @pTotalStaff=100

	   --BEGIN   
		  --RAISERROR('The Total staff is null for this Location !',16,1);
		  --RETURN; 
	   --END


   --Setting staff range

	SELECT @TotalStaffRangeId= CASE WHEN @pTotalStaff>15 AND @pTotalStaff<=30 THEN Cast('2' as TINYINT)
	  			                    WHEN @pTotalStaff >30 THEN Cast('3' as TINYINT) 
                                    ELSE CAST(1 as TINYINT) END 


  
	--PrINT 'TotalStaffRangeId :' + Cast(@TotalStaffRangeId as varCHAR(5))


 SELECT @CountyFactor=CountyMultiplierPct,@MarketTier=MarketTier
 FROM EnterpriseSalesPricing.[prc].[Market]
 WHERE MarketID=@pHomeMarketId

   IF (@pIndustryTypeGroupId IS NULL)
	  SET @pIndustryTypeGroupId=1
  

  
 SELECT @BusinessType= CASE WHEN @pIndustryTypeGroupID=1 THEN 'B'
			WHEN @pIndustryTypeGroupID=2 THEN 'B' 
			WHEN @pIndustryTypeGroupID=3 THEN 'B' 
			WHEN @pIndustryTypeGroupID=4 THEN 'C' 
			WHEN @pIndustryTypeGroupID=5 THEN 'V' END 



 --Getting market tier
   
 SELECT @MarketTier = MarketTier
 FROM   EnterpriseSalesPricing.prc.Market (nolock)
 WHERE MarketId = @pHomeMarketId  AND VersionId = @VersionId; 


   SET @SKU='M'+ISNULL(@BusinessType,'B')+'0'+CAST(@MarketTier as varchar(3))+Cast(@ProductID as varchar(2))+
          CASE WHEN @CurrentUserCount<10 Then '00'+CAST(@CurrentUserCount as varchar(5))
		       WHEN @CurrentUserCount >=10 and @CurrentUserCount<100 Then '0'+CAST(@CurrentUserCount as varchar(3))  ELSE cast(@CurrentUserCount as varchar(4)) END +
		  CASE WHEN @pnumberofMarket<10 Then '00'+CAST(@pnumberofMarket as varchar(3))
		       WHEN @pnumberofMarket >=10 and @pnumberofMarket<100 Then '0'+CAST(@pnumberofMarket as varchar(3))  ELSE cast(@pnumberofMarket as varchar(3)) END 
			
   
   --Select @HomeMarketId
  --Calculate the suite Price


  if @pdebug = 1
  begin 
  print @VersionId
  print @pUserCount
  print @TotalStaffRangeId
  print @pIndustryTypeGroupId
  print @pProductCategoryId
  print @pHomeMarketId
  print @pHomeStateCD

  end 

SELECT  @SuitePrice= EnterpriseSalesPricing.Prc.fnPropertyTenantMarketPrice(@VersionId,@pUserCount,@TotalStaffRangeId,@pIndustryTypeGroupId,@pProductCategoryId,@pHomeMarketId,@pHomeStateCD) 
  
  SET @CountyPrice=@SuitePrice

  IF (@SuitePrice IS NULL or @SuitePrice=0)
	   BEGIN   
		  RAISERROR('This Location cannot be priced at this time because of missing information  !',10,1);
		  Update stg.RevenueItemRaw set CanBePriced=0 Where ContractID=@pContractID
		  RETURN; 
	   END

  --Inserting the Suite Price, 1 market and two Market price in the table

  IF OBJECT_ID('Tempdb..#MarketPrice') IS NOT NULL DROP TABLE #MarketPrice
      CREATE TABLE #MarketPrice(MarketPrice VARCHAR(40),Price MONEY)

  IF @pnumberofMarket=1
    INSERT #MarketPrice(MarketPrice,Price)
    VALUES('SuitePrice'   ,@SuitePrice)
     
	 --SELECT @TotalMarketPrice=	@SuitePrice
  --END

  IF @pnumberofMarket=2 
    INSERT #MarketPrice(MarketPrice,Price)
    VALUES('SuitePrice'   ,@SuitePrice),      
          ('Markets2Price',@SuitePrice*@TwoMarketFactor)


  IF @pnumberofMarket=3 
      INSERT #MarketPrice(MarketPrice,Price)
      VALUES('SuitePrice'   ,@SuitePrice),      
           ('Markets2Price',@SuitePrice*@TwoMarketFactor),
		   ('Markets3Price',@SuitePrice*@ThreeMarketFactor)
	
	  
  -- Getting the price for all subsequent markets
 IF   (@pnumberofMarket>3 )
  BEGIN
     INSERT #MarketPrice(MarketPrice,Price)
      VALUES('SuitePrice'   ,@SuitePrice),      
            ('Markets2Price',@SuitePrice*@TwoMarketFactor),
		    ('Markets3Price',@SuitePrice*@ThreeMarketFactor)

    SELECT @ID=4 , @CurrentPrice=@SuitePrice*@ThreeMarketFactor 

   WHILE (@ID<=@pnumberofMarket)
    BEGIN
      SELECT @Currentmarket='Market'+CAST(@ID as VarCHAR(5))+'Price', @CurrentPrice=@CurrentPrice+@SuitePrice*@MarketFactor

	  INSERT #MarketPrice (MarketPrice,Price)
	  VALUES(@Currentmarket,@CurrentPrice)
	  
	  SET @ID+=1

   END
  
  END

 -- select * from #MarketPrice

  --getting National price and implementation fee

   --SELECT @VersionId VersionId,@pUserCount UserCount,@TotalStaffRangeId TotalStaffRange ,@IndustryTypeGroupId IndustryTypeGroup,@pProductCategoryId ProductCategory,@HomeMarketId HomeMarket,@HomeStateAbbr HomeStateAbbr
    SELECT @TotalMarketPrice=MAX(Price) FROM #MarketPrice

	----County price 
  
  IF @marketTier in (1,2,3)
	   SET @CountyPrice=@SuitePrice*@CountyFactor

    IF OBJECT_ID('Tempdb..#CountyPrice') IS NOT NULL DROP TABLE #CountyPrice
      CREATE TABLE #CountyPrice(CountyPrice VARCHAR(40),Price MONEY)

  IF @pnumberofMarket=1
    INSERT #CountyPrice(CountyPrice,Price)
    VALUES('CountyPrice'   ,@CountyPrice)
     
	
  --multiple counties computations

  IF @pnumberofMarket=2 
    INSERT #CountyPrice(CountyPrice,Price)
    VALUES('CountyPrice'   ,@CountyPrice),      
          ('Markets2Price' ,@CountyPrice*@TwoMarketFactor)


  IF @pnumberofMarket=3 
      INSERT #CountyPrice(CountyPrice,Price)
      VALUES('CountyPrice'   ,@CountyPrice),      
           ('County2Price'   ,@CountyPrice*@TwoMarketFactor),
		   ('County3Price'   ,@CountyPrice*@ThreeMarketFactor)
	
	  
  -- Getting the price for all subsequent markets
 IF   (@pnumberofMarket>3 )
  BEGIN
     INSERT #CountyPrice(CountyPrice,Price)
      VALUES('CountyPrice'   ,@CountyPrice),      
            ('County2Price'  ,@CountyPrice*@TwoMarketFactor),
		    ('County3Price'  ,@CountyPrice*@ThreeMarketFactor)

    SELECT @ID=4 , @CurrentPrice=@CountyPrice*@ThreeMarketFactor 

   WHILE (@ID<=@pnumberofMarket)
    BEGIN
      SELECT @Currentmarket='County'+CAST(@ID as VarCHAR(5))+'Price', @CurrentPrice=@CurrentPrice+@CountyPrice*@MarketFactor

	  INSERT #CountyPrice (CountyPrice,Price)
	  VALUES(@Currentmarket,@CurrentPrice)
	  
	  SET @ID+=1

   END
  
  END

  --getting National price and implementation fee

   --SELECT @VersionId VersionId,@pUserCount UserCount,@TotalStaffRangeId TotalStaffRange ,@IndustryTypeGroupId IndustryTypeGroup,@pProductCategoryId ProductCategory,@HomeMarketId HomeMarket,@HomeStateAbbr HomeStateAbbr
   	SELECT @TotalCountyPrice=MAX(Price) FROM #CountyPrice
 	SELECT @NationalPrice         = EnterpriseSalesPricing.Prc.fnPropertyTenantNationalPrice(@VersionId,@pUserCount,@TotalStaffRangeId,@pIndustryTypeGroupId,@pProductCategoryId,@pHomeMarketId,@pHomeStateCD),
		   @ImplementationFeePrice= EnterpriseSalesPricing.Prc.fnPropertyTenantImplementationPrice(@VersionId,@pUserCount,@TotalStaffRangeId,@pIndustryTypeGroupId,@pProductCategoryID,@pHomeMarketId,@pHomeStateCD) 

 INSERT INTO #MarketPrice(MarketPrice,Price)
 VALUES ('NationalPrice',@NationalPrice),('ImplementationFeePrice',@ImplementationFeePrice),('SalesUnitID',@SalesUnitID) 

 -- returning the price. Return detail price by market if requested or total price otherwise.

 IF @pProductMarketTypeID in (1,6)  select @SKU as SKU, @TotalMarketPrice as ListPrice
 
 IF @pProductMarketTypeID=3 select @SKU as SKU, @NationalPrice as ListPrice
   
 IF @pProductMarketTypeID in (4) select @SKU as SKU, @TotalCountyPrice as ListPrice
  

 
   
if @pdebug = 2
begin 
  SELECT @VersionId VersionID,@pContractID ContractID,@pProductMarketTypeID ProductMarketTypeID,@SKU SKU,@pLocationID LocationID,@MarketTier MarketTier,@pUserCount UserCount,
         @BusinessType BusinessType,@ProductID ProductCount , @pnumberofMarket numberofMarket,
         @TotalMarketPrice TotalMarketPrice,@NationalPrice NationalPrice,getdate() UpdatedDate
  
end

GO
