USE [RevPro]
GO
/****** Object:  StoredProcedure [stg].[spStageOneContract]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [stg].[spStageOneContract]
	 (@pContractLocationID int = null, @pDebug bit = 0,
	 @pYear int = 0, @pMonth int = 0)
AS
	----------------------------
	---		STEP 1			----
	----------------------------

	declare @StartDate date = '12/1/2014'
	declare @EndDate date = '12/31/2030'

	if isnull(@pYEar,0) > 0 and isnull(@pmonth,0) >0
	begin
		set @startDate = cast(cast(@pMonth as varchar(2)) + '/1/' + cast(@pYear as varchar(4)) as date)
		select @EndDate = dateadd(dd,  daysinmonth - 1, @StartDate)
			from lookups.Calendar where datekey = @StartDate 
		print @StartDate
		print @EndDate
	end

--declare @pContractLocationID int = 227734, @pDebug bit = 0
insert into RevenueRun (RevenueRunDate) 
select GetDate()

declare @RevenueRunID int = 0;
select @RevenueRunID = SCOPE_IDENTITY();
	
-- get all events from teh revenueEvent System
INSERT [RevenueProcessing].[stg].[RevenueItemRaw] (
       [LineItemID]
      ,[EventDate]
      ,[ProductID]
	  ,[AdjustedEventDate]
      ,[AdjustedEventYear]
      ,[AdjustedEventMonth]
	  ,[BillingStartDate]
	  ,[BillingMonth]
      ,[LineItemTypeID]
      ,[RenewalDate]
	  ,[OldRenewalDate]
      ,[TermEndDate]
      ,[NumberOfUsers]
      ,[ContractID]
      ,[CoStarSubsidiaryID]
      ,[MonetaryUnitID]
      ,[BillingLocationID]
      ,[SiteLocationID]
      ,[SiteLocationName]
      ,[AEContactID]
      ,[LineItemStatusID]
       ,DiscountedMonthlyPrice
	   ,PriorDiscountedMonthlyPrice
	   ,DiscountedMonthlyPriceDifference
	   ,MonthlyPrice 
       ,ContractApprovedDate
	  ,SalesUnitID
	  ,BundleID
	  ,RevenueItemType
	  ,CurrentTermStartDate
	  ,LocationID 
	  ,RevenueRunID
	  ,SequenceNumber
	  ,[RevenueEventType]
	  ,IsMajor
   )  
	SELECT new.LineItemID,
	       new.EventDate EventDate,
	       new.ProductID,
		   new.AdjustedEventDate ,
		   new.AdjustedEventYear,
		   new.AdjustedEventMonth,
		   cast (null as dateTime ) [BillingStartDate],
	       cast (null as char(6)) BillingMonth,
		   new.LineItemTypeID,
		   new.newrenewaldate RenewalDate,
		   new.oldREnewalDate OldRenewalDate,
			cast (null as dateTime ) TermEndDate,
		   cast (null as int ) NumberOfUsers,
		   new.ContractID,
		   new.CoStarSubsidiaryID,
		   new.MonetaryUnitID,
		   c.BillingLocationID,
		   new.SiteLocationID, 
		   L.LocationName,
		  isnull( L.CurrentAEContactID,0) as AEContactID,
		   0  LineItemStatusID ,
		  ISNULL(new.EndRevenue, 0) DiscountedMonthlyPrice,
		  ISNULL(new.BeginRevenue , 0) PriorDiscountedMonthlyPrice,
		  ISNULL(new.EndRevenue, 0) - ISNULL(new.BeginRevenue , 0) DiscountedMonthlyPriceDifference ,
		  ISNULL(new.EndRevenue,0 ) MonthlyPrice,
		  c.AcctApprovedDate,
		  cast (null as int) SalesUnitID,
		  cast (null as int) BundleID,
		  'SalesOrder'  RevenueItemType,
		  cast (null as datetime) CurrentTermStartDate,
		  c.LocationID,
		  @RevenueRunID,
		  Sequencenumber = ROW_NUMBER() over (partition by lineitemid, AdjustedEventDate order by eventdate),
		  new.EventType,
		  0 IsMajor
	FROM   [EnterpriseReporting].[dbo].[RevenueEvent] new
		LEFT JOIN [EnterpriseSub].dbo.Contract c WITH (NOLOCK) ON c.ContractID=new.ContractID 
		LEFT JOIN [EnterpriseSub].dbo.Location L WITH (NOLOCK) ON c.LocationID=L.LocationID 
	where new.CoStarSubsidiaryID=1 and case when @pContractLocationID is null then 1 else c.LocationID end =  case when @pContractLocationID is null then 1 else @pContractLocationID end
	and AdjustedEventDate between @StartDate and @EndDate 
		and new.eventType not in ('OneTime')

	-- find data from the snapshot event that corresponds to the new state of the event.
	update t set 
		--t.RenewalDate = li.RenewalDate,
		--t.TermEndDate = li.TermEndDate,
		t.NumberOfUsers = li.NumberOfUsers,
		t.LineItemStatusID = li.LineItemStatusID,
		t.SalesUnitID = li.SalesUnitID,
		t.BundleID = li.BundleID,
		t.CurrentTermStartDate = li.CurrentTermStartDate,
		t.DiscountedMonthlyPrice = case when t.DiscountedMonthlyPrice is null then li.DiscountedMonthlyPricePending else t.DiscountedMonthlyPrice end
		from [stg].[RevenueItemRaw] t
			inner join [EnterpriseDataMartSub].dbo.LineItemSnapshot li WITH (NOLOCK) on t.LineItemID = li.LineItemID and t.EventDate = li.LineItemStartDate
			and  t.RevenueRunID = @RevenueRunID
		
	
	

			-- get the billing start date of teh first posted invoice

Update r
set BillingStartDate= a.BillingStartDate, CurrentTermMonths = months + 1
from stg.RevenueItemRaw r
inner join 
(select rir.LineItemID, min(id.BillingStartDate) BillingStartDate, min(ct.TermMonths) months
	from stg.RevenueItemRaw rir
		inner join [Enterprise].dbo.InvoiceDetail id on id.LineItemID = rir.LineItemID
		inner join [Enterprise].dbo.Invoice i on i.InvoiceID = id.InvoiceID
		inner join [Enterprise].dbo.InvoiceBatch ib on ib.InvoiceBatchID = i.InvoiceBatchID
		left join [Enterprise].dbo.ContractTerm ct on id.BillingTermID = ct.ContractTermID 
			where ib.PostedDate is not null and rir.RevenueRunID = @RevenueRunID
			group by rir.LineItemID ) a on a.LineItemID = r.LineItemID

	-- try and find the needed data from the day of or after the BSD is set
				update t set 
		t.RenewalDate = li.RenewalDate,
		t.TermEndDate = coalesce(li.TermEndDate, li.RenewalDate) ,
		t.CurrentTermStartDate = li.CurrentTermStartDate
		from [stg].[RevenueItemRaw] t
			inner join [EnterpriseDataMartSub].dbo.LineItemSnapshot li WITH (NOLOCK) 
			on t.LineItemID = li.LineItemID and (dateadd(d, 1,t.billingstartdate)  = li.LineItemStartDate or t.billingstartdate = li.LineItemStartDate)
			where  t.RevenueRunID = @RevenueRunID and t.RevenueEventType in ( 'NewContract', 'Replace')


update rir set CurrentContractTerm = 
floor((datediff(mm, billingstartdate, AdjustedEventDate)
+ case when DatePart (DAY,AdjustedEventDate) > DatePart(day, billingstartdate) then 1 else 0 end) /12.00) + 1
	from [stg].[RevenueItemRaw] rir
		where  rir.RevenueRunID = @RevenueRunID

	-- get invoices

	
-- load CRM Invoices

INSERT [RevenueProcessing].[stg].[RevenueItemRaw] (
       [LineItemID]
      ,[EventDate]
      ,[ProductID]
	  ,[AdjustedEventDate]
      ,[AdjustedEventYear]
      ,[AdjustedEventMonth]
	  ,[CRMInvoiceDate]
	  ,[BillingStartDate]
	  ,[BillingMonth]
      ,[LineItemTypeID]
      ,[RenewalDate]
      ,[TermEndDate]
      ,[NumberOfUsers]
      ,[ContractID]
      ,[CoStarSubsidiaryID]
      ,[MonetaryUnitID]
      ,[BillingLocationID]
      ,[SiteLocationID]
      ,[SiteLocationName]
      ,[AEContactID]
      ,[LineItemStatusID]
       ,DiscountedMonthlyPrice
       ,ContractApprovedDate
	  ,SalesUnitID
	  ,BundleID
	  ,RevenueItemType
	  ,CurrentTermStartDate
	  ,LocationID 
	  ,RevenueRunID
	  ,SequenceNumber
	  ,CRMInvoiceDetailID
   )  
	SELECT id.LineItemID,
			cast(cast(id.ChargeMonth as varchar(2)) + '/01/' + cast (id.ChargeYear as varchar(4)) as date)  EventDate,
	       id.ProductID,
		   cast(cast(id.ChargeMonth as varchar(2)) + '/01/' + cast (id.ChargeYear as varchar(4)) as date) AdjustedEventDate ,
		   id.ChargeYear AdjustedEventYear,
		   id.ChargeMonth AdjustedEventMonth,
		    ib.PostedDate CRMInvoiceDate,
		   cast (null as dateTime ) [BillingStartDate],
		   cast (null as char(6)) BillingMonth,
		   li.LineItemTypeID,
		   cast (null as dateTime ) RenewalDate,
			cast (null as dateTime ) TermEndDate,
		   cast (null as int ) NumberOfUsers,
		   id.ContractID,
		   ib.CoStarSubsidiaryID,
		   id.MonetaryUnitID,
		   c.BillingLocationID,
		   id.SiteLocationID, 
		   L.LocationName,
		   L.CurrentAEContactID as AEContactID,
		    0 LineItemStatusID ,
		  id.TotalMonthlyPrice EndRevenue,
		  c.AcctApprovedDate,
		  cast (null as int) SalesUnitID,
		  cast (null as int) BundleID,
		  'CRMInvoice'  RevenueItemType,
		  cast (null as datetime) CurrentTermStartDate,
		  c.LocationID,
		  @RevenueRunID,
		   ROW_NUMBER() over (partition by id.LineItemID,  Year(ib.PostedDate), MONTH(ib.PostedDate) order by ib.InvoiceBatchID) ,
		   id.InvoiceDetailID

	FROM [Enterprise].dbo.InvoiceDetail id  WITH (NOLOCK)
		inner join [Enterprise].dbo.Invoice i WITH (NOLOCK) on i.InvoiceID = id.InvoiceID
		inner join [Enterprise].dbo.InvoiceBatch ib WITH (NOLOCK) on ib.InvoiceBatchID = i.InvoiceBatchID
		inner join [Enterprise].dbo.Contract c WITH (NOLOCK) on c.ContractID = id.ContractID
		inner join [Enterprise].dbo.LineItem  li WITH (NOLOCK) on li.LineItemID = id.LineItemID
		LEFT JOIN [EnterpriseSub].dbo.Location L WITH (NOLOCK) ON c.LocationID=L.LocationID 
	inner join (select distinct LineItemID from [stg].[RevenueItemRaw] --where RevenueRunID = @RevenueRunID
		) a on a.LineItemID = id.LineItemID -- to be filtered for active meas
			where ib.PostedDate is not null -- posted
	and c.CoStarSubsidiaryID=1 and case when @pContractLocationID is null then 1 else c.LocationID end =  case when @pContractLocationID is null then 1 else @pContractLocationID end
	--and ib.InvoiceYear >=2015
	and ib.BuildDate  between @StartDate and @EndDate 
	and not exists (select null from [RevenueProcessing].[stg].[RevenueItemRaw] ri
		where  ri.RevenueItemType = 'CRMInvoice' and ri.lineitemid = id.LineItemID 
			and adjustedeventdate = cast(cast(id.ChargeMonth as varchar(2)) + '/01/' + cast (id.ChargeYear as varchar(4)) as date )
				and eventdate = cast(cast(id.ChargeMonth as varchar(2)) + '/01/' + cast (id.ChargeYear as varchar(4)) as date) )
					

	-- NAVISION Invoices

	-- put navision data into temp table and map. MUST move the temp table to the raw table so that we capture NAV only invoices
	

	
INSERT [RevenueProcessing].[stg].[RevenueItemRaw] (
       [LineItemID]
      ,[EventDate]
      ,[ProductID]
	  ,[AdjustedEventDate]
      ,[AdjustedEventYear]
      ,[AdjustedEventMonth]
	  ,[BillingStartDate]
	  ,[BillingMonth]
      ,[LineItemTypeID]
      ,[RenewalDate]
      ,[TermEndDate]
      ,[NumberOfUsers]
      ,[ContractID]
      ,[CoStarSubsidiaryID]
      ,[MonetaryUnitID]
      ,[BillingLocationID]
      ,[SiteLocationID]
      ,[SiteLocationName]
      ,[AEContactID]
      ,[LineItemStatusID]
       ,DiscountedMonthlyPrice
       ,ContractApprovedDate
	  ,SalesUnitID
	  ,BundleID
	  ,RevenueItemType
	  ,CurrentTermStartDate
	  ,LocationID 
	  ,RevenueRunID
	  ,SequenceNumber
	  ,[NAVDocumentNo]
	  ,[NAVUnitPrice]
	  ,[NAVAmount]
	  ,[NAVLineNo]
	  ,[NAVQuantity]
	  ,[NAVBillingStartDate]
	  ,[NAVBillingEndDate]
	  ,[NAVDescription3]
	  ,[NavInvoiceDate]

   )  

SELECT 
	ni.[Line Item ID] LineItemID,
	       ni.[Posting Date] EventDate,
	       li.ProductID ProductID,
		   ni.[Posting Date] [AdjustedEventDate],
		   cast( null as int)[AdjustedEventYear],
		   cast( null as varchar(6)) [AdjustedEventMonth],
		   cast (null as dateTime ) [BillingStartDate],
	       cast (null as char(6)) BillingMonth,
		   li.LineItemTypeID LineItemTypeID,
		   cast (null as dateTime ) RenewalDate,
		   cast (null as dateTime ) TermEndDate,
		   cast (null as int ) NumberOfUsers,
		   ni.[Contract ID],
		   1 CoStarSubsidiaryID, -- default for RIG
		   1 MonetaryUnitID, -- default for RIG
		   sh.[Bill-to Customer No_] [BillingLocationID],
		   ni.[Site ID] [SiteLocationID],
		    ni.[Site Name] LocationName,
		    cast('' as varchar(10)) AEContactID,
		   0   LineItemStatusID ,
		  Amount EndRevenue,
		  cast (null as datetime)  AcctApprovedDate,
		  cast (null as int) SalesUnitID,
		  cast (null as int) BundleID,
		  'NAVInvoice'  RevenueItemType,
		  cast (null as datetime) CurrentTermStartDate,
		  sh.[Sell-to Customer No_] LocationID,
		  @RevenueRunID,
		     ROW_NUMBER() over (partition by ni.[Line Item ID], Year(ni.[Posting Date]),   MONTH(ni.[Posting Date]) order by ni.[Posting Date]) ,
		  ni.[Document No_] [NAVDocumentNo],
		  ni.[Unit Price] [NAVUnitPrice],
		  ni.Amount [NAVAmount],
		  ni.[Line No_] [NAVLineNo],
		  ni.Quantity [NAVQuantity],
		  null [NAVBillingStartDate],
		  null [NAVBillingEndDate],
		  ni.[Description 3] NAVDescription3,
		  ni.[Posting Date] NavInvoiceDate

FROM   [NavisionDB260Sub].[dbo].[RIG$Sales Invoice Line] ni
INNER JOIN dbo.[rig$sales Invoice Header 09292016] sh  ON sh.No_ = ni.[Document No_]
INNER JOIN dbo.[RIG$CRM Invoice Batch 09292016] ib (nolock) on ib.[Batch ID] = sh.[CRM Invoice Batch ID]
inner join (select distinct LocationID  from [stg].[RevenueItemRaw] --where RevenueRunID = @RevenueRunID
	) a on cast(a.LocationID as varchar(100)) = sh.[Sell-to Customer No_]
left join [Enterprise].dbo.LineItem  li WITH (NOLOCK) on li.LineItemID = ni.[Line Item ID] -- shoudl be a look-back
WHERE sh.[Posting Date]  between @StartDate and @EndDate --AND len([Description 3])=24 
	and isnumeric (sh.[Bill-to Customer No_]) = 1
--create clustered index ix_lineitem on #tmpNavisionData(LineitemID,SiteLocationID,AdjustedBillMonth)

-- figure out the dates

update  [RevenueProcessing].[stg].[RevenueItemRaw] 
			set NAVBillingEndDate=CONVERT(DATE,right([NAVDescription3], len([NAVDescription3]) - charindex(' to ',[NAVDescription3] + ' to ') - 3)),
               NAVBillingStartDate=CONVERT(DATE,left([NAVDescription3], len([NAVDescription3]) - charindex(' to ',[NAVDescription3] + ' to ') - 3)),
			   [AdjustedEventYear]=Year(CONVERT(DATE,left([NAVDescription3], len([NAVDescription3]) - charindex(' to ',[NAVDescription3] + ' to ') - 3))),
			   [AdjustedEventMonth]=MOnth(CONVERT(DATE,left([NAVDescription3], len([NAVDescription3]) - charindex(' to ',[NAVDescription3] + ' to ') - 3)))
			    where RevenueRunID = @RevenueRunID and  RevenueItemType =  'NAVInvoice' AND len(NAVDescription3)=24  


--			   -- map onto CoStar invoices. 
--update rir
--set   [NAVDocumentNo]=[Document No_]
--      ,[NAVInvoiceDate]=[Posting Date]
--      ,[NAVUnitPrice]=UnitPrice
--      ,[NAVAmount] =Amount
--	  ,[NAVLineNo]    =[Line No_]
--      ,[NAVQuantity]= Quantity
--	  ,[NAVBillingStartDate]=StartDate
--      ,[NAVBillingEndDate]=EndDate
--from [stg].[RevenueItemRaw] rir
--inner join #tmpNavisionData t on t.LineitemID=rir.LineitemID 
--Where rir.Linetype='CRMInvoice' and t.SitelocationID=rir.SiteLocationID 
--     -- needs redo
--		and rir.AdjustedEventDate = t.[Posting Date]
--		and rir.DiscountedMonthlyPrice = t.Amount
	 -- and t.startdate between  s.AdjustedEventMonth  and s.AdjustedEventMonth 

	-- CRM CREDIT Memos

	--NAV Credit Memos


	
INSERT [RevenueProcessing].[stg].[RevenueItemRaw] (
       [LineItemID]
      ,[EventDate]
      ,[ProductID]
	  ,[AdjustedEventDate]
      ,[AdjustedEventYear]
      ,[AdjustedEventMonth]
	  ,[BillingStartDate]
	  ,[BillingMonth]
      ,[LineItemTypeID]
      ,[RenewalDate]
      ,[TermEndDate]
      ,[NumberOfUsers]
      ,[ContractID]
      ,[CoStarSubsidiaryID]
      ,[MonetaryUnitID]
      ,[BillingLocationID]
      ,[SiteLocationID]
      ,[SiteLocationName]
      ,[AEContactID]
      ,[LineItemStatusID]
       ,DiscountedMonthlyPrice
       ,ContractApprovedDate
	  ,SalesUnitID
	  ,BundleID
	  ,RevenueItemType
	  ,CurrentTermStartDate
	  ,LocationID 
	  ,RevenueRunID
	  ,SequenceNumber
	  ,[NAVDocumentNo]
	  ,[NAVUnitPrice]
	  ,[NAVAmount]
	  ,[NAVLineNo]
	  ,[NAVQuantity]
	  ,[NAVBillingStartDate]
	  ,[NAVBillingEndDate]
	  ,[NAVDescription3]

   )  
	
SELECT 
	ni.[Line Item ID] LineItemID,
	       ni.[Posting Date] EventDate,
	       li.ProductID ProductID,
		   ni.[Posting Date] [AdjustedEventDate],
		   cast( null as int)[AdjustedEventYear],
		   cast( null as varchar(6)) [AdjustedEventMonth],
		   cast (null as dateTime ) [BillingStartDate],
	       cast (null as char(6)) BillingMonth,
		   li.LineItemTypeID LineItemTypeID,
		   cast (null as dateTime ) RenewalDate,
		   cast (null as dateTime ) TermEndDate,
		   cast (null as int ) NumberOfUsers,
		   ni.[Contract ID],
		   1 CoStarSubsidiaryID, -- default for RIG
		   1 MonetaryUnitID, -- default for RIG
		   sh.[Bill-to Customer No_] [BillingLocationID],
		   ni.[Site ID] [SiteLocationID],
		    ni.[Site Name] LocationName,
		    cast('' as varchar(10)) AEContactID,
		   0   LineItemStatusID ,
		  -1 * sld.Amount EndRevenue,
		  cast (null as datetime)  AcctApprovedDate,
		  cast (null as int) SalesUnitID,
		  cast (null as int) BundleID,
		  'NAVCreditMemo'  RevenueItemType,
		  cast (null as datetime) CurrentTermStartDate,
		  sh.[Sell-to Customer No_] LocationID,
		  @RevenueRunID,
		     ROW_NUMBER() over (partition by ni.[Line Item ID], Year(ni.[Posting Date]),   MONTH(ni.[Posting Date]) order by ni.[Posting Date]) ,
		  ni.[Document No_] [NAVDocumentNo],
		  ni.[Unit Price] [NAVUnitPrice],
		  -1 * sld.Amount [NAVAmount],
		  ni.[Line No_] [NAVLineNo],
		  ni.Quantity [NAVQuantity],
		  null [NAVBillingStartDate],
		  null [NAVBillingEndDate],
		  ni.[Description 3] NAVDescription3

FROM   [NavisionDB260Sub].[dbo].[RIG$Sales Invoice Line] ni
left JOIN dbo.[rig$sales Invoice Header 09292016] sh  ON sh.No_ = ni.[Document No_]
left JOIN dbo.[RIG$CRM Invoice Batch 09292016] ib (nolock) on ib.[Batch ID] = sh.[CRM Invoice Batch ID]
inner join (select distinct LocationID  from [stg].[RevenueItemRaw] --where RevenueRunID = @RevenueRunID
	) a on cast(a.LocationID as varchar(100)) = sh.[Sell-to Customer No_]
left join Enterprise.dbo.LineItem  li WITH (NOLOCK) on li.LineItemID = ni.[Line Item ID] -- shoudl be a look-back
INNER JOIN [RevenueProcessing].dbo.[RIG$Sales Invoice Ledger 09292016] SLD ON SLD.[Invoice No_] = ni.[Document No_] AND SLD.[Line No_] = ni.[Line No_]
 WHERE  sld.[Doc_ Type]=3 and sh.[Posting Date]  between @StartDate and @EndDate 
        and isnumeric (sh.[Bill-to Customer No_]) = 1


   RAISERROR (N'Getting raw Data Done ',10,1) with nowait

GO
