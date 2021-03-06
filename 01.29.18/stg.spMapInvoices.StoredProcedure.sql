USE [RevPro]
GO
/****** Object:  StoredProcedure [stg].[spMapInvoices]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [stg].[spMapInvoices]
	 @pDebug bit , @pRevenueRunID int
AS
		update nav set nav.CRMInvoicedetailid = crm.CRMInvoicedetailid
		from stg.revenueitemraw nav
			inner join stg.revenueitemraw crm on nav.lineitemid = crm.lineitemid 
				and nav.AdjustedEventMonth = crm.AdjustedEventMonth
				and nav.AdjustedEventYear = crm.AdjustedEventYear
				
				where nav.RevenueItemType = 'NAVInvoice'
					and crm.revenueitemtype = 'CRMInvoice'
					and nav.RevenueRunID = @pRevenueRunID
					and crm.RevenueRunID = @pRevenueRunID

update crm set crm.ismappedtonav = 1, ignoreflag = 1
		from stg.revenueitemraw nav
			inner join stg.revenueitemraw crm on nav.lineitemid = crm.lineitemid 
				and nav.CRMInvoicedetailid = crm.CRMInvoicedetailid
				where nav.RevenueItemType = 'NAVInvoice'
					and crm.revenueitemtype = 'CRMInvoice'
					and nav.RevenueRunID = @pRevenueRunID
					and crm.RevenueRunID = @pRevenueRunID

		-- set the invoices to the mea they fall in. Use the Navision start date to map.
			update t set mea = m.mea
		from stg.revenueitemraw t
			inner join opt.meacontract mc on mc.contractid = t.contractid 
				inner join opt.mea m on m.mea = mc.mea
					and t.NAVBillingStartDate between m.meastartdate and m.meaenddate
					where t.RevenueRunID = @pRevenueRunID
					and (RevenueItemType = 'NAVInvoice'  or (RevenueItemType = 'CRMInvoice' and isnull(IgnoreFlag,0) = 0)) 

		update t set DerivedProductID = tt.DerivedProductID, 
						DerivedProductName = tt.DerivedProductName,
						DerivedSalesUnitID = tt.DerivedSalesUnitID,
						BundleId = tt.bundleid,
						Quantity_ORdered = tt.Quantity_Ordered,
						AptBundleID = tt.AptBundleID,
						CoStarBrandID = tt.costarbrandid
						
			from stg.vwInvoiceRevenueItemRaw t
							inner join stg.vwSalesOrderRevenueItemRaw tt
								on tt.lineitemid = t.LineItemID and t.mea = tt.mea
								where tt.IgnoreFlag = 0 and t.RevenueRunID = @pRevenueRunID

--update t set t.ListPrice  = ListPrice * ( DiscountedMonthlyPrice / UNIT_SELL_PRICE)
--		FROM stg.vwInvoiceRevenueItemRaw  t 
--			inner join opt.mea m on m.mea = t.mea
--		where RevenueItemType = 'navinvoice' and RevenueRunID = @pRevenueRunID 
--			and m.MEAType = 'Contract Creation'

						

		--update t set EXT_AMOUNT = DiscountedMonthlyPrice,
		--	EXT_AMOUNT_LISTPRICE = ListPrice,
		--	MonthlyPrice = DiscountedMonthlyPrice
			
		--	from stg.vwInvoiceRevenueItemRaw t
		--	where t.IgnoreFlag = 0 and t.RevenueRunID = @pRevenueRunID


RETURN 0

GO
