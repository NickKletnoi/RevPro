USE [RevPro]
GO
/****** Object:  StoredProcedure [stg].[spGroupRevenueItems]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [stg].[spGroupRevenueItems]
	( @pDebug bit , @pRevenueRunID int )

AS

 
 
INSERT INTO [stg].[RevenueItemGrouped]
           ([MEA]
           ,[RevenueItemType]
           ,[AdjustedEventDate]
           ,[CurrentSKU]
           ,[SequenceNumber]
           ,[SOB_ID]
           ,[MonthSequence]
           ,[CurrentContractTerm]
           ,[DaysInStubMonth]
           ,[StubDays]
           ,[StubDailyRate]
           ,[StubDailyListRate]
           ,[StubPeriodMonthlyDiscountedRate]
           ,[DerivedProductID]
           ,[DerivedProductName]
           ,[DerivedSalesUnitID]
           ,[AdjustedEventYear]
           ,[AdjustedEventMonth]
           ,[BillingStartDate]
           ,[CurrentTermStartDate]
           ,[BillingMonth]
           ,[LineItemEndDate]
           ,[AptBundleID]
           ,[RenewalDate]
           ,[TermEndDate]
           ,[ContractApprovedDate]
           ,[NumberOfUsers]
           ,[ContractID]
           ,[CoStarBrandID]
           --,[BundleID]
           ,[CoStarSubsidiaryID]
           ,[SiteLocationID]
           ,[MonetaryUnitID]
           ,[BillingLocationID]
           ,[SiteLocationName]
           ,[LineType]
           ,[NAVDocumentNo]
           ,[NAVLineNo]
           ,[NAVQuantity]
           ,[NAVUnitPrice]
           ,[NAVAmount]
           ,[NAVBillingStartDate]
           ,[NAVBillingEndDate]
           ,[NAVInvoiceDate]
           ,[NAVDescription3]
           ,[AEContactID]
           ,[LineItemStatusID]
           ,[IsCreditCard]
           ,[DiscountedMonthlyPrice]
           ,[ProductMarketTypeID]
           ,[MonthsOfFullDiscount]
           ,[IsInternContract]
           ,[PropertyID]
           ,[ProductMarketTypeDesc]
           ,[ListPrice]
           ,[MonthlyPrice]
           ,[QUANTITY_ORDERED]
           ,[STUB_AMOUNT]
           ,[AdjustedBillingStartDate]
           ,[STUB_AMOUNT_LISTPRICE]
           ,[EXT_AMOUNT]
           ,[EXT_AMOUNT_LISTPRICE]
           ,[BillingLocationName]
           ,[CountryCode]
           ,[AEContactName]
           ,[IsMajor]
           ,[UseContractUserLimit]
           ,[CurrentTermMonths]
           ,[LocationID]
           ,[RevenueRunID]
		   ,LineItemTypeID
		   ,LineItemCreatedDate)
           
 
 select
           [MEA]
           ,case  [RevenueItemType]
			when 'SalesOrder' then 'SalesOrder'
			when 'SalesOrderCorr' then 'SalesOrder'
			when 'CRMInvoice' then 'InvoiceC'
			when 'NAVInvoice' then 'Invoice'
			when 'NAVCreditMemo' then 'CreditMemo'
			end [RevenueItemType]
           ,[AdjustedEventDate]
           ,[CurrentSKU]
           ,[SequenceNumber]
           ,[SOB_ID]
           ,min([MonthSequence])
           ,max([CurrentContractTerm]) [CurrentContractTerm]
           ,min([DaysInStubMonth]) [DaysInStubMonth]
           ,max([StubDays]) [StubDays] -- danger - only important when aggregating multiple stubs
           ,sum([StubDailyRate]) [StubDailyRate]
           ,sum([StubDailyListRate])[StubDailyListRate]
           ,sum([StubPeriodMonthlyDiscountedRate])  [StubPeriodMonthlyDiscountedRate]
           ,[DerivedProductID]
           ,[DerivedProductName]
           ,min([DerivedSalesUnitID])
           ,[AdjustedEventYear]
           ,[AdjustedEventMonth]
           ,min([BillingStartDate])
           ,min([CurrentTermStartDate])
           ,[BillingMonth]
           ,[LineItemEndDate]
           ,[AptBundleID]
           ,[RenewalDate]
           ,[TermEndDate]
           ,[ContractApprovedDate]
           ,min([NumberOfUsers]) [NumberOfUsers]
           ,[ContractID]
           ,[CoStarBrandID]
           --,[BundleID]
           ,[CoStarSubsidiaryID]
           ,[SiteLocationID]
           ,[MonetaryUnitID]
           ,[BillingLocationID]
           ,[SiteLocationName]
           ,[LineType]
           ,[NAVDocumentNo]
           ,min([NAVLineNo]) [NAVLineNo]
           ,min([NAVQuantity]) [NAVQuantity]
           ,sum([NAVUnitPrice]) [NAVUnitPrice]
           ,sum([NAVAmount]) [NAVAmount]
           ,[NAVBillingStartDate]
           ,[NAVBillingEndDate]
           ,[NAVInvoiceDate]
           ,[NAVDescription3]
           ,[AEContactID]
           ,[LineItemStatusID]
           ,[IsCreditCard]
           ,sum([DiscountedMonthlyPriceDifference] ) [DiscountedMonthlyPrice]
           ,[ProductMarketTypeID]
           ,min([MonthsOfFullDiscount]) [MonthsOfFullDiscount]
           ,[IsInternContract]
           ,min([PropertyID]) [PropertyID]
           ,[ProductMarketTypeDesc]
           ,sum([ListPrice]) [ListPrice]
           ,sum([MonthlyPrice]) [MonthlyPrice]
           ,[QUANTITY_ORDERED]
           ,sum(case when [STUB_AMOUNT] > 0 then [STUB_AMOUNT] else 0 end ) [STUB_AMOUNT] -- don't send negative stubs. they are internal for pro-ration
           ,min([AdjustedBillingStartDate]) [AdjustedBillingStartDate]
           ,sum(case when [STUB_AMOUNT_LISTPRICE] > 0 then [STUB_AMOUNT_LISTPRICE] else 0 end ) [STUB_AMOUNT_LISTPRICE]-- don't send negative stubs. they are internal for pro-ration
           ,sum([EXT_AMOUNT])[EXT_AMOUNT]
           ,sum([EXT_AMOUNT_LISTPRICE]) [EXT_AMOUNT_LISTPRICE]
           ,[BillingLocationName]
           ,[CountryCode]
           ,[AEContactName]
           ,[IsMajor]
           ,[UseContractUserLimit]
           ,[CurrentTermMonths]
           ,[LocationID]
           ,[RevenueRunID]
		   , LineItemTypeID
		   , min(LineItemCreatedDate) CreatedDate
    	from stg.revenueItemRaw 
			where RevenueRunID = @pRevenueRunID
			--and revenueitemtype = 'salesorder'
			and ignoreflag = 0
			and mea is not null
			and CurrentSKU is not null
			and RevenueEventType not in ('CRMInvoice')
		group by MEA, RevenueItemType, AdjustedEventDate, CurrentSku, SOB_ID, 
			--CurrentContractTerm, 
			--DaysInStubMonth, 
			--StubDays,
			SequenceNumber, --MonthSequence, 
			DerivedProductID, DerivedProductName, 
			--DerivedSalesUnitID, 
			AdjustedEventMonth, AdjustedEventYear,
			BillingMonth, LineItemEndDate, AptBundleID, renewaldate, TermEndDate, ContractApprovedDate, 
			contractid, costarbrandid, --BundleID, 
			CoStarSubsidiaryID, SiteLocationID, MonetaryUnitID, 
			BillingLocationID, SiteLocationName, LineItemTypeID, LineType, 
			NAVDocumentNo, --NAVLineNo, 
			--NAVQuantity, NAVUnitPrice,  
			NAVBillingStartDate,
			NAVBillingEndDate, NAVDescription3, NAVInvoiceDate, AEContactID, AEContactName, LineItemStatusID, 
			IsCreditCard, ProductMarketTypeID, IsInternContract,  ProductMarketTypeDesc, 
			QUANTITY_ORDERED, 
			--AdjustedBillingStartDate, 
			BillingLocationName, CountryCode,
			IsMajor, UseContractUserLimit, CurrentTermMonths , locationid, RevenueRunID, LineItemTypeID



				



RETURN 0

GO
