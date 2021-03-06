USE [RevPro]
GO
/****** Object:  StoredProcedure [stg].[spPricingDriver]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [stg].[spPricingDriver]
		 (@pContractLocationID int = null, @pDebug bit , @pRevenueRunID int )
AS

if @pDebug = 1 print 'Starting' +  OBJECT_NAME(@@PROCID)
	select distinct mea , 0 IsProcessedFlag
	into #tmpMEA
	from stg.vwSalesOrderRevenueItemRaw where RevenueRunID = @pRevenueRunID

	declare @mea varchar(100)
	declare @msg varchar(100)

	select top 1 @mea = t.MEA
			from #tmpMEA t where IsProcessedFlag = 0

	declare @thecounter int = 0
	while  @mea is not null
		begin

			exec stg.spSuitePricingDriver @pMEA = @mea, @pDebug = @pDebug
		
			exec stg.spApartmentsPricingDriver @pMEA = @mea, @pDebug = @pDebug

			exec stg.spCMAPricingDriver @pMEA = @mea, @pDebug = @pDebug

			update t set IsProcessedFlag = 1 
				 from #tmpMEA t
					where  @mea = t.MEA

			set @thecounter = @thecounter + 1
	 		if @thecounter %100 = 0 
			
			begin
				set @msg = 'Done Pricing ' + cast ( @MEA  as varchar(100))
				RAISERROR (@msg,10,1) With nowait; 
			end
			 
			--print 'Done Pricing ' + cast ( @MEA  as varchar(100))

			set @mea = null
			select top 1 @mea = t.MEA
			from #tmpMEA t where IsProcessedFlag = 0
		end

		-- apply pricing to the line items.

			update rir set ListPrice =  mcc.ComponentPrice / mcc.RevenueLineItemCount, CurrentSKU = SKU, SOB_ID = mcc.MEAContractComponentID
				from stg.RevenueItemRaw rir
					inner join opt.MEAContractComponentLineItem mccl on mccl.LineItemID  = rir.LineItemID
					inner join opt.MEAContractComponent mcc on mcc.MEAContractComponentID = mccl.MEAContractComponentID
					inner join opt.MEAContract mc on mc.MEAContractID = mcc.MEAContractID and mc.MEA = rir.mea and mc.ContractID = rir.ContractID
				where RevenueRunID = @pRevenueRunID and mccl.IsFreeIgnoredFlag = 0


	
						
				--		update rir set ListPrice =  mcc.ComponentPrice / mcc.LineItemCount, CurrentSKU = SKU, SOB_ID = mcc.MEAContractComponentID
				--from stg.RevenueItemRaw rir
				--	inner join opt.MEAContractComponentLineItem mccl on mccl.LineItemID  = rir.LineItemID
				--	inner join opt.MEAContractComponent mcc on mcc.MEAContractComponentID = mccl.MEAContractComponentID
				--	inner join opt.MEAContract mc on mc.MEAContractID = mcc.MEAContractID and mc.MEA = rir.mea and mc.ContractID = rir.ContractID
				--	inner join (select lineitemid, mea,  min(monthsequence) m 
				--		from stg.RevenueItemRaw  rr where RevenueRunID = @pRevenueRunID  and ignoreflag = 0
				--			group by lineitemid, mea) a on a.LineItemID = rir.LineItemID
				--			and a.m = rir.MonthSequence
				--			and a.MEA = rir.mea
				--where RevenueRunID = @pRevenueRunID 
				--	and rir.ignoreFLag = 0
					

		if @pDebug = 1 print 'Ending' +  OBJECT_NAME(@@PROCID)
RETURN 0

GO
