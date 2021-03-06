USE [RevPro]
GO
/****** Object:  UserDefinedFunction [stg].[fnMultiStatePrice]    Script Date: 1/29/2018 3:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [stg].[fnMultiStatePrice]
(
  @pVersionId tinyint
, @pUserCount smallint -- number of users requested
, @pTotalStaffRangeId tinyint -- 1)"1 - 15" 2)"16 - 30" 3)"31 +"  
, @pIndustryTypeGroupId tinyint -- 1)Brokerage / Consultants 2)Appraisal / Valuation / Tax Appeal 3)Institutional Investment / Lender 5)Vendor
, @pProductCategoryId int -- 1)Express 2)Professional 3)2-Product 4)Suite 5)Suite + SC 6)1-Product
, @pHomeMarketId smallint -- names identified in Market table
, @pHomeStateAbbr char(2)  -- required
, @pStateListToBuy  stg.StateList READONLY 

)
returns Money  
as

BEGIN
  
 /*
 Declare
   @pVersionId tinyint=2
	, @pUserCount smallint=3 -- number of users requested
	, @pTotalStaffRangeId tinyint=1 -- 1)"1 - 15" 2)"16 - 30" 3)"31 +"  
	, @pIndustryTypeGroupId tinyint=3 -- 1)Brokerage / Consultants 2)Appraisal / Valuation / Tax Appeal 3)Institutional Investment / LENDer 5)VENDor
	, @pProductCategoryId tinyint =4 --  2)1-Product 3)2-Product 4)Suite 
	, @pHomeMarketId smallint =132 -- names identified in Market table
	, @pHomeStateAbbr char(2)   = 'DC' -- required
	, @pStateListToBuy  prc.StateList

	INSERT @pStateListToBuy (StateCode)
    Values ('AK'),('AL'),('CA'),('VA'),('GA'),('NJ')
	SELECT [prc].[fnMultiStatePrice](@pVersionId, @pUserCount, @pTotalStaffRangeId,@pIndustryTypeGroupId,@pProductCategoryId,@pHomeMarketId,@pHomeStateAbbr,@pStateListToBuy)

 */
	DECLARE
	  @adProductCategoryId tinyint 
	, @stateMultiplier Float
	, @price Money
	, @Productprice Money
	, @IndustryTypeProductPrice Money
	, @totalStaffRangePrice Money
	, @ProductUserAddOnPrice Money
	, @NationalPrice Money
	, @pUserAddOnTypeId int=1
	, @HomeMarketTier Tinyint
    , @VersionID Tinyint
  

  --Getting the latest version

    SELECT TOP 1 @VersionID=VersionId
	FROM  EnterpriseSalesPricing.prc.[MarketUserProductPrice] 
	WHERE CurrentPrice=1

  --Getting The Market tier
   
    SELECT @HomeMarketTier = MarketTier
    FROM   EnterpriseSalesPricing.prc.Market (nolock)
    WHERE MarketId = @pHomeMarketId  AND VersionId = @VersionId;

  --Checking if the Home state is null	
  
  IF @pHomeStateAbbr IS NULL
    BEGIN 
	   --PRINT 'ERROR: You must specify a last name for the sales person.'
	   SELECT @price= (SELECT CAST(('You must select a home state !!!!') AS INT))
       RETURN(-10000)
	END 
  
 ---- State(s)  to buy should be specified

   IF (SELECT COUNT(*) FROM @pStateListToBuy)=0
    BEGIN 
	   --PRINT 'ERROR: You must specify a last name for the sales person.'
	   SELECT @price= (SELECT CAST(('You must select the state to buy !!!!') AS INT))
       RETURN(-10000)
	END 

   -- assiging local variable @adProductCategoryId

   SELECT  @adProductCategoryId =
           CASE @pProductCategoryId 
		       WHEN 2 THEN 6
               WHEN 4 THEN 3
			   ELSE @pProductCategoryId END  
   
  -- getting the @totalStaffRangePrice (price base of user range)

	SELECT @totalStaffRangePrice=ListPrice
	FROM [EnterpriseSalesPricing].[prc].[TotalStaffRangePrice]
	WHERE VersionID=@pVersionId AND TotalStaffRangeId=@pTotalStaffRangeId And ProductCategoryId=@pProductCategoryID
  
  --Getting the National price

   SELECT  @NationalPrice=EnterpriseSalesPricing.Prc.fnPropertyTenantNationalPrice(@VersionId,@pUserCount,@pTotalStaffRangeId,@pIndustryTypeGroupId,@pProductCategoryId,@pHomeMarketId,@pHomeStateAbbr)

  --getting Market price

  SELECT @Productprice=EnterpriseSalesPricing.prc.fnStateMarketPrice(@pVersionId,@pUserCount,@pTotalStaffRangeId,@pIndustryTypeGroupId,@pProductCategoryId,@pHomeMarketId,@pHomeStateAbbr)

  -- getting the price per add on user

   SELECT @ProductUserAddOnPrice=ListPrice
   FROM [EnterpriseSalesPricing].[prc].[ProductUserAddOnPrice]
   WHERE Versionid=@pVersionId and Usercount=@pUsercount and ProductCategoryId=@adProductCategoryId and UserAddOnTypeId=@pUserAddOnTypeId

   --SELECT @Productprice Productprice,@totalStaffRangePrice totalStaffRangePrice,@pProductCategoryid  ProductCategoryid, @adProductCategoryId adProductCategoryId, @ProductUserAddOnPrice ProductUserAddOnPrice

  -- getting the state multiplier	 

    IF (SELECT COUNT(*) FROM @pStateListToBuy)=1
	    SELECT @stateMultiplier=statemultiplierPct
        FROM EnterpriseSalesPricing.prc.State
        WHERE  VersionId=@pVersionId AND StateCd=(SELECT StateCode FROM @pStateListToBuy)
    
	IF (SELECT COUNT(*) FROM @pStateListToBuy)>1 
		SELECT @stateMultiplier=(SUM(statemultiplierPct)/133)*100
		FROM EnterpriseSalesPricing.prc.State
		WHERE  VersionId=@pVersionId AND StateCd IN (SELECT StateCode FROM @pStateListToBuy)

    IF ((SELECT COUNT(*) FROM @pStateListToBuy)>1 AND EXISTS(SELECT 1 FROM @pStateListToBuy WHERE StateCode='CA') AND @stateMultiplier<0.66 )  --specific case for California
	   SET @stateMultiplier=0.66+0.05 

   --getting the @IndustryTypeProductPrice

	SELECT @IndustryTypeProductPrice=ListPrice
	FROM [EnterpriseSalesPricing].[prc].[IndustryTypeProductPrice]
	WHERE IndustryTypeGroupId=@pIndustryTypeGroupId AND ProductCategoryId =@pProductCategoryId  

  -- Vendor Price

 IF @pIndustryTypeGroupId=5 --vendor price
    BEGIN 

	  SET @pUserAddOnTypeId =2
	  SELECT @ProductUserAddOnPrice=ListPrice
	  FROM [EnterpriseSalesPricing].[prc].[ProductUserAddOnPrice]
	  WHERE Versionid=@pVersionId and Usercount=@pUsercount and ProductCategoryId=@adProductCategoryId and UserAddOnTypeId=@pUserAddOnTypeId

	IF @adProductCategoryId =3
	  BEGIN 
	    SELECT @price=(@ProductUserAddOnPrice+7250)*0.75*@stateMultiplier

	   IF @stateMultiplier=0
	      SELECT @price=@Productprice
       IF @stateMultiplier>0 AND  (SELECT COUNT(*) FROM @pStateListToBuy) >4
	      SELECT @price=(@ProductUserAddOnPrice+7250)*0.75*@stateMultiplier
     END
	 
   IF @adProductCategoryId =6
     BEGIN
	   SELECT @price=(@ProductUserAddOnPrice+5450)*0.75*@stateMultiplier
	 END
   	  	
	IF @price<@Productprice*1.22
	   SET @price=@Productprice*1.22	 	

  END	 

  --Institutional Investment / Lender price

 IF (@pIndustryTypeGroupId=3 And @stateMultiplier>0) --Institutional Investment / Lender price
    BEGIN 
	 IF (@pProductCategoryId =4)
	   BEGIN
	     
		 SET @adProductCategoryId=3

	   	 SELECT @ProductUserAddOnPrice=ListPrice
         FROM [EnterpriseSalesPricing].[prc].[ProductUserAddOnPrice]
         WHERE Versionid=@pVersionId and Usercount=@pUsercount and ProductCategoryId=@adProductCategoryId and UserAddOnTypeId=@pUserAddOnTypeId

	      SELECT @price=(ISNULL(@ProductUserAddOnPrice,0)+@IndustryTypeProductPrice)*@stateMultiplier

       END ELSE
          
		  SELECT @price=(ISNULL(@ProductUserAddOnPrice,0)+@IndustryTypeProductPrice)*@stateMultiplier

   END

  --1)Brokerage / Consultants 2)Appraisal / Valuation / Tax Appeal

   IF (@pIndustryTypeGroupId IN (1,2) )--AND NOT EXISTS(SELECT 1 FROM @pStateListToBuy WHERE StateCode='CA')) -- 1)Brokerage / Consultants 2)Appraisal / Valuation / Tax Appeal
      BEGIN 
	    SELECT @price=@Productprice + (@totalStaffRangePrice*@stateMultiplier)
      END


  --IF (@pIndustryTypeGroupID=3) AND (@price>@NationalPrice)
  --    SET @price=@NationalPrice 


 RETURN ROUND(@price  ,0)
  	 
END;



GO
