USE [RevPro]
GO
/****** Object:  StoredProcedure [stg].[spCMAPricingDriver]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [stg].[spCMAPricingDriver]
		@pMEA varchar(100), @pDebug bit
AS

if @pDebug = 1 print 'Starting' +  OBJECT_NAME(@@PROCID)


	declare @ContractID int,
	@MEAContractID int,
     @VersionID tinyint
	  ,@UnitCount int
	 ,@LocationID int
	  ,@IndustrialSqFt int
	  ,@OfficeSqFt int
	  ,@RetailSqFt int
	  ,@MarketsWithNoProperties int
	, @ContractTermID int= Null
	



	select t.MEA, t.MEAContractID, t.ContractID, t.UnitCount, t.IndustrialSqFt, t.OfficeSqFt, t.RetailSqFt, t.MarketsWithNoProperties, 
		t.ComponentID LocationID,	0 IsProcessedFlag
	into #tmp 
	from [dbo].vwMEAPricingCMA  t where MEA = @pmea

	
   
   if @pDebug = 1
   begin
	print 'Contents of #tmp'
	select * from #tmp 
   end

   
   	select top 1 
		 @LocationID = locationid, @IndustrialSqFt = t.IndustrialSqFt, @UnitCount = t.UnitCount, @OfficeSqFt = t.OfficeSqFt, @RetailSqFt = t.RetailSqFt , 
		 @MarketsWithNoProperties = t.MarketsWithNoProperties,  @MEAContractID = t.MEAContractID 
			from #tmp t where IsProcessedFlag = 0
	


	while  @LocationID is not null
		begin

		declare @o TABLE (ProductID int, SKU varchar(100), ListPrice money , description varchar(100))

		insert into @o (ProductID, SKU, ListPrice, description)
		exec stg.spPriceCMA
			@pNoPropertyMarketCount = @MarketsWithNoProperties,
			@pRetailSqFt = @RetailSqFt,
			@pIndustrialSqFt = @IndustrialSqFt,
			@pOfficeSqFt = @OfficeSqFt,
			@pMFCount = @UnitCount,
			@pProductID = 266
			, @pDebug= @pDebug

		update t set SKU = isnull(tt.SKU, 'ERROR'), t.ComponentPrice =isnull( tt.ListPrice,0)
			from opt.MEAContractComponent t
				cross join @o tt
				where t.MEAContractID = @MEAContractID and t.ComponentID = @LocationID and t.ComponentType = 'InfoLocationCMA'

	
		update t set IsProcessedFlag = 1 
		 from #tmp t
			where  @MEAContractID = t.MEAContractID 
				and @LocationID = t.LocationID 

	 	if @pDebug = 1 print 'Done Processing ' + cast ( @LocationID  as varchar(100))
			set @LocationID = null;

			 
   	select top 1 
		 @LocationID = locationid, @IndustrialSqFt = t.IndustrialSqFt, @UnitCount = t.UnitCount, @OfficeSqFt = t.OfficeSqFt, @RetailSqFt = t.RetailSqFt , 
		 @MarketsWithNoProperties = t.MarketsWithNoProperties,  @MEAContractID = t.MEAContractID 
			from #tmp t where IsProcessedFlag = 0
	
		end
		if @pDebug = 1 print 'Ending' +  OBJECT_NAME(@@PROCID)
RETURN 0

GO
