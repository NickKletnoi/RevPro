USE [RevPro]
GO
/****** Object:  StoredProcedure [stg].[spApartmentsPricingDriver]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [stg].[spApartmentsPricingDriver]
	@pMEA varchar(100), @pDebug bit
AS

if @pDebug = 1 print 'Starting' +  OBJECT_NAME(@@PROCID)


	declare @ContractID int,
	@MEAContractID int,
     @VersionID tinyint
	  ,@UnitCount int
	  ,@WeightedAvgRentPerSqFt float
	  ,@IsBundle int
	  ,@PropertyID int
	  ,@EquivalentProductID int
	, @ContractTermID int= Null
	



	select t.MEA, t.MEAContractID, t.ContractID, t.UnitCount, t.AvgRentPerSqFt, t.IsBundle , t.EquivalentProductID, 
		t.ComponentID PropertyID,	0 IsProcessedFlag
	into #tmp 
	from [dbo].vwMEAPricingApartment  t where MEA = @pmea

	
   
   if @pDebug = 1
   begin
	print 'Contents of #tmp'
	select * from #tmp 
   end

   
   	select top 1 
		 @PropertyID = t.PropertyID, @UnitCount = t.UnitCount, @IsBundle = t.IsBundle, @WeightedAvgRentPerSqFt = t.AvgRentPerSqFt , 
		 @EquivalentProductID = t.EquivalentProductID,  @MEAContractID = t.MEAContractID 
			from #tmp t where IsProcessedFlag = 0
	


	while  @PropertyID is not null
		begin

		declare @o TABLE (SKU varchar(100), ListPrice money )

		delete from @o

		insert into @o (SKU, ListPrice)
		exec stg.spPriceApartments
  @pUnitCount = @UnitCount
  ,@pWeightedAvgRentPerSqFt = @WeightedAvgRentPerSqFt
  ,@pIsBundle = @ISbundle
  ,@pEquivalentProductID  = @EquivalentProductID
	, @pContractTermID = null
	, @pDebug = @pDEbug

			update t set SKU = isnull(tt.SKU, 'ERROR'), t.ComponentPrice =isnull( tt.ListPrice,0)
			from opt.MEAContractComponent t
				cross join @o tt
				where t.MEAContractID = @MEAContractID and t.ComponentID = @PropertyID and t.ComponentType = 'ApartmentPropertyListing'

	
		update t set IsProcessedFlag = 1 
		 from #tmp t
			where  @MEAContractID = t.MEAContractID 
				and @PropertyID = t.PropertyID and @EquivalentProductID = t.EquivalentProductID

	 	if @pDebug = 1 print 'Done Processing ' + cast ( @PropertyID  as varchar(100))
			set @PropertyID = null;

			 
   	select top 1 
		  @PropertyID = t.PropertyID,@UnitCount = t.UnitCount, @IsBundle = t.IsBundle, @WeightedAvgRentPerSqFt = t.AvgRentPerSqFt , 
		 @EquivalentProductID = t.EquivalentProductID,  @MEAContractID = t.MEAContractID 
			from #tmp t where IsProcessedFlag = 0
	
		end
		if @pDebug = 1 print 'Ending' +  OBJECT_NAME(@@PROCID)
RETURN 0

GO
