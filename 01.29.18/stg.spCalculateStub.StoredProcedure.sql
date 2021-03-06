USE [RevPro]
GO
/****** Object:  StoredProcedure [stg].[spCalculateStub]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [stg].[spCalculateStub]
	 (@pRevenueRunID int, @pDebug bit = 0)
AS
RAISERROR (N'Starting stub amount routine Please wait !',10,1) With nowait;


	update r set 
	r.StubDailyRate = (r.DiscountedMonthlyPriceDifference/ DaysInStubMonth * 1.00),
	r.STUB_AMOUNT = (r.DiscountedMonthlyPriceDifference/ DaysInStubMonth * 1.00) * StubDays,
	r.StubDailyListRate = (r.ListPrice / DaysInStubMonth * 1.00),
	r.STUB_AMOUNT_LISTPRICE = (r.ListPrice / DaysInStubMonth * 1.00) * StubDays
		from  stg.[vwAllSalesOrderRevenueItemRaw] r 
			where RevenueRunID = @pRevenueRunID 

			-- override with 0 where appropriate. Renewals have no stub
		update r set r.STUB_AMOUNT = 0 	, r.STUB_AMOUNT_LISTPRICE =0 , r.StubDays = 0, r.StubDailyListRate = 0, r.StubDailyRate = 0
		from  stg.[vwAllSalesOrderRevenueItemRaw] r 
			where ((MEAInvoiceBillingStartDate <= MEAInvoiceFirstDateOfPeriod)
				or StubDays = DaysInStubMonth  -- stub is a full month
				or stubdays = 0
				or RevenueEventType = 'Renewal') and RevenueRunID = @pRevenueRunID -- last day of months
				

		-- at this point, the system has updated several ignored sos

				update t set STUB_AMOUNT = p
			from  stg.revenueitemraw t
				inner join (
			select m.mea, lineitemid, sum(stub_amount)  p
				from stg.revenueitemraw  rir
					inner join opt.mea m on m.mea = rir.mea
					where m.MEALevel =2 
						and ignoreflag = 1
						and isnull(stub_amount, 0) >0
						and rir.RevenueRunID = @pRevenueRunID 
					group by  m.mea, lineitemid) a on a.MEA = t.mea and 
					a.LineItemID = t.LineItemID 
					and t.IgnoreFlag = 0 
					and t.RevenueRunID = @pRevenueRunID 

	

	-- special case of mid-term cancel

	update r set 
				r.stubdays = c.daysRemain,
				r.daysInStubMonth = daysInMonth,
				r.StubDailyRate = abs((r.DiscountedMonthlyPriceDifference/ daysInMonth * 1.00)) * -1.00,
				r.STUB_AMOUNT = abs((r.DiscountedMonthlyPriceDifference/ daysInMonth * 1.00)) * -1.00 * c.daysRemain,
				r.StubDailyListRate = abs((r.ListPrice / daysInMonth * 1.00)) * -1.00,
				r.STUB_AMOUNT_LISTPRICE = abs((r.ListPrice / daysInMonth * 1.00)) * -1.00 * c.daysRemain -- negate as this comes in positive

				--select m.meaenddate, , daysInMonth
				from stg.revenueitemraw  r
					inner join opt.mea m on m.mea = r.mea
					inner join lookups.calendar c on c.datekey  = m.meaenddate
					where actiontype = 'Correction' --and RevenueEventType <> 'Cancel'
					and day (m.meaenddate) > 1
					and r.StubDays = 0


					-- now remove listprice frmo all but the last sequence item so it doesn't duplicate

						update rir set ListPrice =  0, DiscountedMonthlyPrice = 0, DiscountedMonthlyPriceDifference = 0, PriorDiscountedMonthlyPrice = 0, monthlyprice = 0
				from stg.RevenueItemRaw rir
					inner join opt.MEAContractComponentLineItem mccl on mccl.LineItemID  = rir.LineItemID
					inner join opt.MEAContractComponent mcc on mcc.MEAContractComponentID = mccl.MEAContractComponentID
					inner join opt.MEAContract mc on mc.MEAContractID = mcc.MEAContractID and mc.MEA = rir.mea and mc.ContractID = rir.ContractID
					inner join (select lineitemid, mea,  max(monthsequence) m 
						from stg.RevenueItemRaw  rr where RevenueRunID = @pRevenueRunID  and ignoreflag = 0
							group by lineitemid, mea) a on a.LineItemID = rir.LineItemID
							and a.m <> rir.MonthSequence
							and a.MEA = rir.mea
				where RevenueRunID = @pRevenueRunID 
					and rir.ignoreFLag = 0

					-- calculate extended values the grouping will do final summing

		update r set EXT_AMOUNT = (isnull( DiscountedMonthlyPrice, 0) * isnull(r.QUANTITY_ORDERED,0)) + r.STUB_AMOUNT,
		EXT_AMOUNT_LISTPRICE  = (isnull( ListPrice, 0) * isnull(r.QUANTITY_ORDERED,0)) + r.STUB_AMOUNT_LISTPRICE
		from stg.[vwAllSalesOrderRevenueItemRaw] r 
				where RevenueRunID = @pRevenueRunID 

	-- what does the MEA thing its list price is by month from componente

		update m	set m.MonthlyListPriceFromComponents  = p
			from opt.mea m
			inner join (
			select mea, sum (mcc.ComponentPrice) p
				from opt.meacontract mc
					inner join opt.MEAContractComponent mcc on mc.MEAContractID = mcc.MEAContractID
				group by mea
					) a on a.MEA = m.mea 
					where m.RevenueRunID = @pRevenueRunID -- only do this when created


update m	set m.InitialTotalExtendedListPrice = eal,
	m.MonthlyDiscountedPrice = dlp,
	m.InitialTotalExtendedPrice = ea,
	m.MonthlyListPriceFromSalesOrders = lp
	
			from opt.mea m
			inner join (

			select mea, sum(r.ListPrice) lp,
			sum (r.DiscountedMonthlyPrice) dlp,
			sum (r.EXT_AMOUNT) ea, 
			sum (r.EXT_AMOUNT_LISTPRICE) eal
				from stg.vwSalesOrderRevenueItemRaw r 
				where RevenueRunID = @pRevenueRunID and IgnoreFlag = 0
				group by mea
				
				) a on a.MEA = m.MEA
			where m.RevenueRunID = @pRevenueRunID 

			


RAISERROR (N'DONE  stub amount routine!',10,1) With nowait;
RETURN 0

GO
