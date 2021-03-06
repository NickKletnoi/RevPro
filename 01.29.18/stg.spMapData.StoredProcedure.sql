USE [RevPro]
GO
/****** Object:  StoredProcedure [stg].[spMapData]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [stg].[spMapData] (
	@pContractLocationID INT = NULL,
	@pDebug BIT,
	@pRevenueRunID INT,
	@pVerbose bit = 0
	)
AS
	----------------------------
	---		STEP 2			----
	----------------------------
	-- add in any additional data
	-- USE AdjsutedBillingStartDateFromHere 
	IF @pDebug = 1
	BEGIN
		PRINT 'Entering Mapping Proc'
	END

	if @pVerbose = 1 RAISERROR (N'Suppressing ignored products!',10,1)WITH NOWAIT;

	UPDATE rir
	SET ActionType = 'Ignore - Not Processing Product',
		IgnoreFlag = 1
	FROM [stg].[RevenueItemRaw] rir
	INNER JOIN lookups.ProductSetup pr ON pr.productid = rir.ProductID
	WHERE pr.IgnoreFlag = 1 AND rir.RevenueRunID = @pRevenueRunID

	if @pVerbose = 1 RAISERROR (	N'Marking new contracts!',10,1) WITH NOWAIT;

	UPDATE rir
	SET IsContractCreatedThisMonth = 1
	FROM [stg].[RevenueItemRaw] rir
	INNER JOIN lookups.Calendar c ON c.DateKey = rir.EventDate
	WHERE NOT EXISTS (
			SELECT NULL
			FROM EnterpriseDataMartSub..LineItemSnapshot t
			WHERE t.contractid = rir.contractid AND t.LineItemStartDate < dateadd(dd, ((c.DayNumber - 1) * - 1
						), rir.eventdate)
			) AND rir.IgnoreFlag = 0 AND rir.RevenueRunID = @pRevenueRunID

	if @pVerbose = 1 RAISERROR (N'Marking new Line Items!',10,1)WITH NOWAIT;

	UPDATE rir
	SET IsLineItemCreatedThisMonth = 1
	FROM [stg].[RevenueItemRaw] rir
	INNER JOIN lookups.Calendar c ON c.DateKey = rir.EventDate
	WHERE NOT EXISTS (
			SELECT NULL
			FROM EnterpriseDataMartSub..LineItemSnapshot t
			WHERE t.LineItemID = rir.LineItemID AND t.LineItemStartDate < dateadd(dd, ((c.DayNumber - 1) * - 1
						), rir.eventdate)
			) AND rir.IgnoreFlag = 0 AND rir.RevenueRunID = @pRevenueRunID

	if @pVerbose = 1 RAISERROR (N'Marking terminating contracts!',10,1)	WITH NOWAIT;

	UPDATE rir
	SET [IsContractInActiveAtEndOfMonth] = 1 -- iscontract
	FROM [stg].[RevenueItemRaw] rir
	INNER JOIN lookups.Calendar c ON c.DateKey = rir.EventDate
	WHERE not EXISTS (
			SELECT NULL
			FROM EnterpriseDataMartSub..LineItemSnapshot t
			WHERE t.ContractiD = rir.ContractID AND t.LineItemStatusID IN (1, 3) AND 
			dateadd(dd, ((c.DaysRemain )), rir.eventdate) BETWEEN t.LineItemStartDate AND t.LineItemEndDate
			) AND rir.IgnoreFlag = 0 AND rir.RevenueRunID = @pRevenueRunID

	if @pVerbose = 1 RAISERROR (N'Marking terminating LineItems!',10,1)WITH NOWAIT;
	-- really is active on first day of next month...
	UPDATE rir
	SET [IsLIneItemInActiveAtEndOfMonth] = 1 -- iscontract
	FROM [stg].[RevenueItemRaw] rir
	INNER JOIN lookups.Calendar c ON c.DateKey = rir.EventDate
	WHERE not EXISTS (
			SELECT NULL
			FROM EnterpriseDataMartSub..LineItemSnapshot t
			WHERE t.LineItemID = rir.LineItemID AND t.LineItemStatusID IN (1, 3) AND
					dateadd(dd, ((c.DaysRemain )), rir.eventdate) BETWEEN t.LineItemStartDate AND t.LineItemEndDate
			) AND rir.IgnoreFlag = 0 AND rir.RevenueRunID = @pRevenueRunID

	if @pVerbose = 1 RAISERROR (N'Marking never fulfilled contracts!',10,1)WITH NOWAIT;

	UPDATE rir
	SET IgnoreFlag = 1, ActionType = 'Contract Cancelled In First Month, No BSD' -- iscontract
	FROM [stg].[RevenueItemRaw] rir
	WHERE IsLineItemCreatedThisMonth = 1 AND [IsLIneItemInActiveAtEndOfMonth] = 1 AND BillingStartDate IS NULL AND 
		rir.RevenueRunID = @pRevenueRunID

	if @pVerbose = 1 RAISERROR (N'Marking Renewals!',10,1)WITH NOWAIT;

	UPDATE rir
		set RevenueEventType = 'Renewal'
		FROM [stg].[RevenueItemRaw] rir
			where renewalDate > OldRenewalDate 
				AND rir.RevenueRunID = @pRevenueRunID 
				and RevenueEventType = 'Existing'
				and DiscountedMonthlyPriceDifference = 0

	UPDATE rir
	SET IsRenewal = 1 -- iscontract
	FROM [stg].[RevenueItemRaw] rir
	WHERE RevenueEventType = 'Renewal' AND IgnoreFlag = 0 AND rir.RevenueRunID = @pRevenueRunID

	if @pVerbose = 1 RAISERROR (N'Assigning Brand and Product!',10,	1)WITH NOWAIT;

	-- assign brand and product
	UPDATE rir
	SET CoStarBrandID = p.CoStarBrandID,
		ProductName = p.ProductDesc
	FROM stg.RevenueItemRaw rir
	INNER JOIN [EnterpriseSub].dbo.Product p ON p.ProductID = rir.ProductID
	WHERE rir.RevenueRunID = @pRevenueRunID

	if @pVerbose = 1 RAISERROR (N'Assigning Market Info!',10,1) WITH NOWAIT;

	-- assign product market info
	UPDATE rir
	SET ProductMarketTypeID = pm.ProductMarketTypeID,
		ProductMarketTypeDesc = mt.ProductMarketTypeDesc
	FROM stg.RevenueItemRaw rir
	INNER JOIN [EnterpriseSub].dbo.SalesUnitProductMarket supm ON rir.SalesUnitID = supm.SalesUnitID
	INNER JOIN [EnterpriseSub].dbo.ProductMarket pm ON pm.ProductMarketID = supm.ProductMarketID
	INNER JOIN [EnterpriseSub].dbo.ProductMarketType mt ON mt.ProductMarketTypeID = pm.ProductMarketTypeID
	WHERE rir.RevenueRunID = @pRevenueRunID



			
	if @pVerbose = 1 RAISERROR (N'Assigning States!',10,1)WITH NOWAIT;

	UPDATE rir
	SET StateCD = Left(su.SalesUnitCD, 2)
	FROM stg.RevenueItemRaw rir
	INNER JOIN [EnterpriseSub].dbo.salesunit su ON su.SalesUnitID = rir.SalesUnitID
	WHERE su.ProductMarketTypeID = 2 AND su.SalesUnitCD IS NOT NULL AND rir.RevenueRunID = @pRevenueRunID

	if @pVerbose = 1 RAISERROR (N'Converting Plus Sales Units!',10,1)WITH NOWAIT;

	-- map PPW plus units to their non-plus variants

	update r set SalesUnitID = su.SalesUnitID, ActionType = 'Correcting Plus SU'
		from [stg].RevenueItemRaw r
			inner join  [EnterpriseSub].dbo.SalesUnit suOrig on suOrig.SalesUnitID = r.SalesUnitID 
			inner join [EnterpriseSub].dbo.SalesUnit su on su.SalesUnitDesc = rtrim(replace(suOrig.SalesUnitDesc, 'Plus', '')) and su.productid = 1
			where suOrig.SalesUnitDEsc like '% plus'
				and r.ProductId = 1
	if @pVerbose = 1 RAISERROR (N'Assigning Sales Units!',10,1)WITH NOWAIT;

	UPDATE rir
	SET SalesUnitDesc = su.SalesUnitDesc,
		ProductMarketTypeID = CASE WHEN isnull(su.ProductMarketTypeID, 0) = 6 THEN 1 ELSE isnull(su.
					ProductMarketTypeID, 0) END, -- make expansion into market
		ProductMarketTypeDesc = pmt.ProductMarketTypeDesc
	FROM stg.RevenueItemRaw rir
	INNER JOIN [EnterpriseSub].dbo.salesunit su ON su.SalesUnitID = rir.SalesUnitID
	LEFT JOIN [EnterpriseSub].dbo.ProductMarketType pmt ON pmt.ProductMarketTypeID = su.ProductMarketTypeID
	WHERE rir.RevenueRunID = @pRevenueRunID


		-- if no product amrket type, and in a bundle, take the propoerty web component.


			UPDATE rir
	SET ProductMarketTypeID = orig.ProductMarketTypeID,
		ProductMarketTypeDesc = orig.ProductMarketTypeDesc
	FROM stg.RevenueItemRaw rir
		inner join stg.RevenueItemRaw orig on orig.BundleID = rir.BundleID and orig.ProductID = 1
		where isnull(rir.ProductMarketTypeID,0) =0 
			and rir.RevenueRunID = @pRevenueRunID
			and orig.RevenueRunID = @pRevenueRunID

	if @pVerbose = 1 RAISERROR (	N'Assigning Properties for APTs!',10,1) WITH NOWAIT;

	UPDATE rir
	SET PropertyID = l.PropertyID
	FROM stg.RevenueItemRaw rir
	INNER JOIN [EnterpriseSub].dbo.lineitem li ON rir.lineitemid = li.lineitemid 
	INNER JOIN [EnterpriseSub].dbo.ListingSubscription l ON l.LineItemID = li.LineItemID
	WHERE rir.RevenueRunID = @pRevenueRunID AND rir.CoStarBrandID IN (2, 10)

	if @pVerbose = 1 RAISERROR (N'Setting some extra dates!',10,1) WITH NOWAIT;

	UPDATE rir
	SET CurrentContractTerm = 1,
		CurrentTermMonths = 12
	FROM stg.RevenueItemRaw rir
	WHERE rir.RevenueRunID = @pRevenueRunID AND abs(DateDiff(mm, BillingStartDate, adjustedeventdate)) <= 3 AND 
		CurrentContractTerm IS NULL

	-- this will feed so_book date and trans_date
	UPDATE rir
	SET LineItemCreatedDate = li.CreatedDate
	FROM stg.RevenueItemRaw rir
	INNER JOIN [Enterprise].dbo.LineItem li ON li.LineItemID = rir.LineItemID
	WHERE rir.RevenueRunID = @pRevenueRunID

	-- if no currenttermstartdate, use biling start date if in first term
	UPDATE rir
	SET CurrentTermStartDate = BillingStartDate,
		TermEndDate = dateadd(dd, - 1, dateadd(mm, CurrentTermMonths, dateadd(day, - (datepart(dd, BillingStartDate) - 1
						), BillingStartDate))),
		RenewalDate = dateadd(dd, - 1, dateadd(mm, CurrentTermMonths, dateadd(day, - (datepart(dd, BillingStartDate) - 1
						), BillingStartDate)))
	FROM stg.RevenueItemRaw rir
	WHERE rir.RevenueRunID = @pRevenueRunID AND CurrentContractTerm = 1 AND CurrentTermStartDate IS NULL



	if @pVerbose = 1 RAISERROR (N'Setting Current Term Length!',	10,	1	)WITH NOWAIT;

	UPDATE rir
	SET rir.CurrentTermMonths = datediff(mm, rir.CurrentTermStartDate, rir.RenewalDate)
	FROM stg.RevenueItemRaw rir
	WHERE rir.RevenueRunID = @pRevenueRunID

	UPDATE rir
	SET CurrentTermID = ct.ContractTermID
	FROM stg.RevenueItemRaw rir
	INNER JOIN [Enterprise].dbo.ContractTerm ct ON ct.TermMonths BETWEEN rir.CurrentTermMonths - 1 AND rir.
				CurrentTermMonths + 1
	WHERE rir.RevenueRunID = @pRevenueRunID

	if @pVerbose = 1 RAISERROR (	N'Assigning AEs!',	10,1)WITH NOWAIT;

	UPDATE rir
	SET AEContactName = cc.firstName + ' ' + cc.LastName
	FROM stg.RevenueItemRaw rir
	INNER JOIN [EnterpriseSub].dbo.contact cc ON rir.AEContactID = cc.ContactID
	WHERE rir.RevenueRunID = @pRevenueRunID


	if @pVerbose = 1 RAISERROR (	N'Assigning Major Flag!',	10,1)WITH NOWAIT;

	UPDATE rir
	SET ismajor = 1
	FROM stg.RevenueItemRaw rir
	INNER JOIN [EnterpriseSub].dbo.location l on rir.LocationID = l.locationid 
	INNER JOIN [EnterpriseSub].dbo.customerInfo b on l.hqLocationID = b.locationid 
	WHERE rir.RevenueRunID = @pRevenueRunID
		and b.MajorAccountFlag = 1

	if @pVerbose = 1 RAISERROR (N'Assigning Location Data!',10,1) WITH NOWAIT;

	UPDATE rir
	SET BillingLocationName = l.LocationName,
		CountryCode = l.CountryCode
	FROM stg.RevenueItemRaw rir
	INNER JOIN [EnterpriseSub].dbo.location l ON rir.BillingLocationID = l.locationid
	WHERE rir.RevenueRunID = @pRevenueRunID

	UPDATE rir
	SET LocationName = l.LocationName
	FROM stg.RevenueItemRaw rir
	INNER JOIN [EnterpriseSub].dbo.location l ON rir.LocationID = l.locationid
	WHERE rir.RevenueRunID = @pRevenueRunID
	
	if @pVerbose = 1 RAISERROR (N'Figuring out Equivalent Products ',10,1)	WITH NOWAIT

	
	-- first set all propertypro to the same as the ppw sales unit.
	UPDATE r
	SET DerivedSalesUnitID = SalesUnitID
	FROM [stg].RevenueItemRaw r
	WHERE productid = 1 AND r.RevenueRunID = @pRevenueRunID

	


	-- where there are several PPW sales units,  Find lowest numbered equivalent.
	UPDATE r
	SET DerivedSalesUnitID = su
	FROM [stg].RevenueItemRaw r
	INNER JOIN (
		SELECT min(salesunitid) su,
			IsSameAsSalesUnitID
		FROM lookups.EquivalentSalesUnit es
		WHERE productid = 1
		GROUP BY IsSameAsSalesUnitID
		) a ON a.IsSameAsSalesUnitID = r.SalesUnitID
	WHERE productid = 1 AND r.RevenueRunID = @pRevenueRunID

	-- then map all to their equivalent PW sales unit
	UPDATE r
	SET DerivedSalesUnitID = a.su
	FROM [stg].RevenueItemRaw r
	INNER JOIN (
		SELECT min(salesunitid) su,
			IsSameAsSalesUnitID
		FROM lookups.EquivalentSalesUnit es
		WHERE productid = 1
		GROUP BY IsSameAsSalesUnitID
		) a ON a.IsSameAsSalesUnitID = r.SalesUnitID
	WHERE r.productid <> 1 AND r.RevenueRunID = @pRevenueRunID and a.su is not null

	UPDATE r
	SET DerivedProductID = r.ProductID,
		DerivedProductName = ProductName
	FROM [stg].RevenueItemRaw r
	WHERE DerivedProductID IS NULL AND r.RevenueRunID = @pRevenueRunID

	-- set derived product for bundles
	UPDATE r
	SET DerivedProductID = b.BundleTypeID + 10000,
		DerivedProductName = bt.BundleTypeDesc
	FROM [stg].RevenueItemRaw r
	INNER JOIN [Enterprise].dbo.Bundle b ON b.BundleID = r.BundleID
	INNER JOIN [Enterprise].dbo.BundleType bt ON bt.BundleTypeID = b.BundleTypeID 
	where  r.RevenueRunID = 	@pRevenueRunID

	-- fill in any others?
UPDATE r
	SET DerivedSalesUnitID = SalesUnitID
	FROM [stg].RevenueItemRaw r
	WHERE DerivedSalesUnitID is null AND r.RevenueRunID = @pRevenueRunID
	
	if @pVerbose = 1 RAISERROR (N'Figuring out Renewal Events to ignore ',10,1)	WITH NOWAIT

	-- END OLD CODE
	-- TODO: what if the cahnge was invoiced then changed back and credited
	-- When a temporary price change occurs adn no credit is issued, what happens. 
	-- if renewal is followed in same month by unrenewal, ignore
	SELECT rir.RevenueItemRawID,
		a.RevenueItemRawID SecondRevenueItemRawID
	INTO #tmpRenewalEventsToIgnore
	FROM [stg].[RevenueItemRaw] rir
	INNER JOIN (
		SELECT revenueitemrawid,
			lineitemid,
			year(EventDate) EventYear,
			Month(EventDate) EventMonth,
			EventDate
		FROM [stg].[RevenueItemRaw] t
		--left join lookups.RevenueEventTypePrecedence ll on ll.RevenueEventType = t.revenueEventType
		WHERE t.RevenueRunID = @pRevenueRunID AND t.RevenueItemType = 'SalesOrder' AND t.RevenueEventType = 
			'Renewal'
		) a ON a.EventYear = year(rir.EventDate) AND a.EventMonth = month(rir.EventDate) AND a.EventDate < rir.
		EventDate AND a.LineItemID = rir.LineItemID
	WHERE rir.RevenueRunID = @pRevenueRunID AND rir.RevenueItemType = 'SalesOrder' AND rir.RevenueEventType = 
		'UnRenewal'

	UPDATE rir
	SET ActionType = 'Ignore - Renewal-Unrenewal',
		IgnoreFlag = 1
	FROM [stg].[RevenueItemRaw] rir
	INNER JOIN #tmpRenewalEventsToIgnore t ON t.RevenueItemRawID = rir.RevenueItemRawID

	UPDATE rir
	SET ActionType = 'Ignore - Renewal-Unrenewal',
		IgnoreFlag = 1
	FROM [stg].[RevenueItemRaw] rir
	INNER JOIN #tmpRenewalEventsToIgnore t ON t.SecondRevenueItemRawID = rir.RevenueItemRawID

	if @pVerbose = 1 RAISERROR (N'Figuring out not last events  to ignore ',10,1)	WITH NOWAIT
	-- ignore if not last event in a month, except when new-existing
	UPDATE rir
	SET MonthSequence = a.rn,
		ActionType = CASE WHEN rn <> 1 THEN 'Ignore - Not Last SO Action In Month' ELSE NULL END,
		IgnoreFlag = CASE WHEN rn <> 1 THEN 1 ELSE 0 END
	FROM [stg].[RevenueItemRaw] rir
	INNER JOIN (
		SELECT [RevenueItemRawID],
			rn = Row_number() OVER (
				PARTITION BY LineItemID,
				AdjustedEventYear,
				AdjustedEventMonth ORDER BY ll.precedence,
					--adjustedEventDate DESC, 
					eventdate
				)
		FROM [stg].[RevenueItemRaw] t
		LEFT JOIN lookups.RevenueEventTypePrecedence ll ON ll.RevenueEventType = t.revenueEventType
		WHERE t.RevenueRunID = @pRevenueRunID AND t.RevenueItemType = 'SalesOrder'
		) a ON a.RevenueItemRawID = rir.RevenueItemRawID
	WHERE rir.RevenueRunID = @pRevenueRunID AND rir.RevenueItemType = 'SalesOrder' AND isnull(ignoreflag, 0) = 0
		


	UPDATE rir
	SET AdjustedEventMonth = month(AdjustedEventDate),
		AdjustedEventYear = year(AdjustedEventDate)
	FROM stg.RevenueItemRaw rir
	WHERE ActionType = 'ShiftForward' AND rir.RevenueRunID = @pRevenueRunID

	if @pVerbose = 1 RAISERROR (N'Redoing month sequencee ',10,1)	WITH NOWAIT
	-- re-do month sequence after shifting.
	UPDATE rir
	SET MonthSequence = a.rn,
		ActionType = CASE WHEN rn <> 1 THEN 'Ignore - Not Last SO Action In Month' ELSE NULL END,
		IgnoreFlag = CASE WHEN rn <> 1 THEN 1 ELSE 0 END
	FROM [stg].[RevenueItemRaw] rir
	INNER JOIN (
		SELECT [RevenueItemRawID],
			rn = Row_number() OVER (
				PARTITION BY LineItemID,
				AdjustedEventYear,
				AdjustedEventMonth ORDER BY ll.precedence,
					--adjustedEventDate DESC, 
					eventdate
				)
		FROM [stg].[RevenueItemRaw] t
		LEFT JOIN lookups.RevenueEventTypePrecedence ll ON ll.RevenueEventType = t.revenueEventType
		WHERE t.RevenueRunID = @pRevenueRunID AND t.RevenueItemType = 'SalesOrder'
		) a ON a.RevenueItemRawID = rir.RevenueItemRawID
	WHERE rir.RevenueRunID = @pRevenueRunID AND rir.RevenueItemType = 'SalesOrder' AND isnull(ignoreflag, 0) = 0

		-- dont' ignore when new/'existing combos, unless also termed that month
	update rir set IgnoreFlag = 0, ActionType = 'New/Existing in same month'
				from stg.revenueitemraw  rir
					where exists (
							select null from stg.revenueitemraw t2 where t2.IsLineItemCreatedThisMonth = 1 and t2.IsContractCreatedThisMonth = 0
								and t2.LineItemID = rir.LineItemID
								and year(t2.eventdate) = year(rir.eventdate)
								and month(t2.EventDate ) = month(rir.eventdate))
						and rir.RevenueItemType = 'SalesOrder'
						and RevenueEventType in ('new', 'existing')
						and not (IsLineItemCreatedThisMonth = 1 and IsLineItemInactiveAtEndOfMonth = 1 and BillingStartDate is null) 
						and  rir.RevenueRunID = @pRevenueRunID 


	-- map apt bundle pirces together...
	--UPDATE rir
	--SET DiscountedMonthlyPrice = dmp,
	--	MonthlyPrice = dmp
	--FROM [stg].[RevenueItemRaw] rir
	--INNER JOIN (
	--	SELECT aptbundleid,
	--		AdjustedEventYear,
	--		AdjustedEventMonth,
	--		sum(DiscountedMonthlyPrice) / 2 dmp
	--	FROM (
	--		SELECT DISTINCT lineitemid,
	--			aptbundleid,
	--			discountedmonthlyprice,
	--			AdjustedEventYear,
	--			AdjustedEventMonth
	--		FROM [stg].[RevenueItemRaw] rir
	--		WHERE aptbundleid IS NOT NULL AND RevenueItemType = 'SalesOrder' AND ignoreflag = 0 AND 
	--			discountedmonthlyprice > 1 AND rir.RevenueRunID = @pRevenueRunID
	--		) a
	--	GROUP BY aptbundleid,
	--		AdjustedEventYear,
	--		AdjustedEventMonth
	--	) b ON b.AptBundleID = rir.AptBundleID
	--WHERE RevenueItemType = 'SalesOrder' AND ignoreflag = 0 AND rir.RevenueRunID = @pRevenueRunID

	if @pVerbose = 1 RAISERROR (N'mapping escalations ',10,1)	WITH NOWAIT
	-- if lienitem has a renewal and existing, it's an escalation. merge the prices from one to teh other
	--generally, if two events happen on the same date
	UPDATE rir
	SET DiscountedMonthlyPrice = p,
		MonthlyPrice = p
	FROM stg.RevenueItemRaw rir
	INNER JOIN (
		SELECT LineItemID,
			adjustedeventMonth,
			AdjustedEventYear,
			max(discountedmonthlyprice) p
		FROM stg.RevenueItemRaw rt
		WHERE rt.RevenueEventType = 'Existing' AND revenuerunid = @pRevenueRunID
		GROUP BY LineItemID,
			adjustedeventMonth,
			AdjustedEventYear
		) a ON a.LineItemID = rir.LineItemID AND a.AdjustedEventMonth = rir.AdjustedEventMonth AND a.
		AdjustedEventYear = rir.AdjustedEventYear
	WHERE rir.RevenueEventType = 'Renewal' AND revenuerunid = @pRevenueRunID

	
	-- smarter - use only if thre is an ignored item last
	if @pVerbose = 1 RAISERROR (N'Figuring out not last events  to ignore set 2 ',10,1)	WITH NOWAIT
	UPDATE rir
	SET DiscountedMonthlyPrice = ext.DiscountedMonthlyPrice,
		MonthlyPrice = ext.MonthlyPrice,
		PriorDiscountedMonthlyPrice = 0,
		DiscountedMonthlyPriceDifference = ext.DiscountedMonthlyPrice,
		CurrentTermStartDate = ext.CurrentTermStartDate,
		TermEndDate = ext.TermEndDate ,
		RenewalDate = ext.RenewalDate 


	FROM stg.RevenueItemRaw rir
	INNER JOIN (
		SELECT LineItemID,
			adjustedeventMonth,
			AdjustedEventYear,
			max(RevenueItemRawID) LastRevenueItemRawID
		FROM stg.RevenueItemRaw rt
		WHERE rt.RevenueEventType = 'Existing' 
		and ignoreflag = 1
		--AND revenuerunid = @pRevenueRunID
		GROUP BY LineItemID,
			adjustedeventMonth,
			AdjustedEventYear
		) a ON a.LineItemID = rir.LineItemID AND a.AdjustedEventMonth = rir.AdjustedEventMonth AND a.
		AdjustedEventYear = rir.AdjustedEventYear
	INNER JOIN stg.RevenueItemRaw ext ON ext.LineItemID = rir.LineItemID AND a.LastRevenueItemRawID = ext.
		RevenueItemRawID and ext.EventDate > rir.EventDate
	WHERE rir.IsLineItemCreatedThisMonth = 1 
	--AND rir.revenuerunid = @pRevenueRunID 
	and isnull(rir.ActionType,'') <> 'New/Existing in same month'
	and rir.revenueitemtype = 'SalesOrder'
	and rir.ignoreflag = 0
	if @pVerbose = 1 RAISERROR (N'Done Mapping ',10,1)	WITH NOWAIT

RETURN 0

GO
