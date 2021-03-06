USE [RevPro]
GO
/****** Object:  StoredProcedure [stg].[spDetermineStartDates]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [stg].[spDetermineStartDates]
	(@pDebug bit , @pRevenueRunID int , @pVerbose bit = 0)
AS


	----------------------------
	---		STEP 3			----
	----------------------------

		if @pVerbose = 1 RAISERROR (N'Determining Start Dates ',10,1)	WITH NOWAIT
-- todo: MEA scope
-- TODO: move invoicedetail lookups to staged data.
-- get first invoice
	select det.LineItemID, det2.EarliestInvoiceDetailID, det.GrossMonthlyPrice, det.MonthlyPrice, det.BillingStartDate, 
		cast(CAST(det.chargeyear AS VARCHAR(4)) + RIGHT('0' + CAST(det.chargemonth AS VARCHAR(2)), 2) + '01' as DATE) as [MEAInvoiceFirstDateOfPeriod]
into #tmpInvoiceDetail
from [Enterprise].dbo.InvoiceDetail det
		inner join stg.RevenueItemRaw r on r.LineItemID = det.LineItemID 
inner join
	(
	select d.LineItemID as line2, min(InvoiceDetailID) EarliestInvoiceDetailID
	from [Enterprise].dbo.InvoiceDetail d
		inner join stg.RevenueItemRaw rt on rt.LineItemID = d.LineItemID 
			where  RevenueItemType = 'SalesOrder' and isnull(rt.IgnoreFlag,0) = 0 and rt.RevenueRunID = @pRevenueRunID
	group by d.LineItemID
	) det2 on det.InvoiceDetailID = det2.EarliestInvoiceDetailID
	where  RevenueItemType = 'SalesOrder' and isnull(r.IgnoreFlag,0) = 0 and r.RevenueRunID = @pRevenueRunID

	if @pVerbose = 1 RAISERROR (N'Setting invoice detail Start Dates ',10,1)	WITH NOWAIT

		update r set r.MEAFirstInvoiceDetailID = t.EarliestInvoiceDetailID, 
			r.MEAInvoiceBillingFirstPeriodGross = t.GrossMonthlyPrice, 
			r.MEAInvoiceBillingFirstPeriodDiscounted = t.MonthlyPrice, 
			r.MEAInvoiceBillingStartDate = t.BillingStartDate,
			r.MEAInvoiceBillingStartDateDay = day(t.BillingStartDate),
			r.[MEAInvoiceFirstDateOfPeriod] = t.[MEAInvoiceFirstDateOfPeriod]
			from  stg.RevenueItemRaw r
				inner join #tmpInvoiceDetail t on t.LineItemID = r.LineItemID 
				where   RevenueItemType = 'SalesOrder' and isnull(r.IgnoreFlag,0) = 0 and r.RevenueRunID = @pRevenueRunID

-- grab earliest pricing detail
		if @pVerbose = 1 RAISERROR (N'Getting pricing detail Start Dates ',10,1)	WITH NOWAIT
select distinct  det.LineItemID, det2.EarliestLineItemPricingDetailID, det.DiscountedMonthlyPrice, det2.NumberOfUsers
into #firstPricingDetail
from Enterprise.dbo.lineitempricingdetail det
	inner join stg.RevenueItemRaw r on r.LineItemID = det.LineItemID and isnull(r.IgnoreFlag,0) = 0 and r.RevenueRunID = @pRevenueRunID
join
	(
	select pd.LineItemID as line2, min(LineItemPricingDetailID) EarliestLineItemPricingDetailID, max(pd.UserCount) NumberOfUsers
	from [Enterprise].dbo.lineitempricingdetail pd
		inner join stg.RevenueItemRaw rt on rt.LineItemID = pd.LineItemID
	where IsApprovedFlag = 1 and   RevenueItemType = 'SalesOrder' and isnull(rt.IgnoreFlag,0) = 0 and rt.RevenueRunID = @pRevenueRunID 
	group by pd.LineItemID
	) det2 on det.LineItemPricingDetailID = det2.EarliestLineItemPricingDetailID
	where    RevenueItemType = 'SalesOrder' and isnull(r.IgnoreFlag,0) = 0 and r.RevenueRunID = @pRevenueRunID
	
	
	if @pVerbose = 1 RAISERROR (N'Setting pricing detail Start Dates ',10,1)	WITH NOWAIT
	-- if no users are set, check unapproved from first pricing detial
	update r set r.MEAFirstPricingDetailID = t.EarliestLineItemPricingDetailID, 
	r.MEAFirstPricingDetailDiscountedMonthlyPrice = t.DiscountedMonthlyPrice,
		r.NumberOfUsers = case when r.NumberOfUsers = 0 then isnull(t.NumberOfUsers,0) else r.NumberOfUsers end 
			from  stg.RevenueItemRaw r
				inner join #firstPricingDetail t on t.LineItemID = r.LineItemID 
				where   RevenueItemType = 'SalesOrder' and  r.RevenueRunID = @pRevenueRunID
				and 	isnull(r.IgnoreFlag,0) = 0
	
	if @pVerbose = 1 RAISERROR (N'Setting pricing detail Start Dates 2',10,1)	WITH NOWAIT
	-- first pass. will be updated in MEA Assignment
	update r set DaysInStubMonth = invcal.DaysInMonth, StubDays = invcal.DaysRemain 
			from  stg.RevenueItemRaw r
				inner join lookups.Calendar invcal on cast(r.MEAInvoiceBillingStartDate as date) = invcal.datekey
				where   RevenueItemType = 'SalesOrder' and   r.RevenueRunID = @pRevenueRunID 
				--and isnull(r.IgnoreFlag,0)=0  always do this



if @pdebug =1 
begin
	print 'Contents of #firstPricingDetail'
	select * From #firstPricingDetail
end 


-- if it's 0 dollar and created more than 2 month ago and has no invoice details, fill in BSD from line item if possible

	if @pVerbose = 1 RAISERROR (N'Set BSD ',10,1)	WITH NOWAIT
	UPDATE rir
	SET BillingStartDate = li.billingStartDate
	FROM stg.RevenueItemRaw rir
	INNER JOIN [EnterpriseSub].dbo.lineitem li on li.LineItemID = rir.LIneITemID
	WHERE rir.RevenueRunID = @pRevenueRunID
		and  RevenueItemType = 'SalesOrder'
		and rir.DiscountedMonthlyPrice = 0 and rir.MEAFirstInvoiceDetailID is null and li.CreatedDate < dateadd( mm, -2, getdate())
		and rir.BillingStartDate is null

RETURN 0

GO
