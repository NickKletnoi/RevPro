USE [RevPro]
GO
/****** Object:  Table [dbo].[Active_LineItems]    Script Date: 1/29/2018 3:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Active_LineItems](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[ContractID] [int] NOT NULL,
	[LineItemID] [int] NOT NULL,
	[CurrentTermStartDate] [date] NULL,
	[RenewalDate] [date] NULL,
	[BillingStartDate] [date] NULL,
	[DiscountedMonthlyPrice] [numeric](38, 20) NULL,
	[OriginalMonthlyPrice] [numeric](38, 20) NOT NULL,
	[ProductID] [int] NOT NULL,
	[MonetaryUnitID] [tinyint] NOT NULL,
	[SiteLocationID] [int] NOT NULL,
	[LineItemStatusID] [tinyint] NOT NULL,
	[LineItemTypeID] [int] NOT NULL,
	[LineItemInvoiceConfigurationID] [int] NOT NULL,
	[BundleID] [int] NULL,
	[CreatedDate] [smalldatetime] NOT NULL,
	[Stub_Fl] [int] NOT NULL,
	[StubTail_Fl] [int] NOT NULL,
	[StraightLine_Fl] [int] NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Index [nclxActive_LineItems_Contract]    Script Date: 1/29/2018 3:17:39 PM ******/
CREATE CLUSTERED INDEX [nclxActive_LineItems_Contract] ON [dbo].[Active_LineItems]
(
	[ContractID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [clxActive_LineItems_LineItemID]    Script Date: 1/29/2018 3:17:40 PM ******/
CREATE NONCLUSTERED INDEX [clxActive_LineItems_LineItemID] ON [dbo].[Active_LineItems]
(
	[LineItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [nclxActive_LineItems_CurrentTermStarDate]    Script Date: 1/29/2018 3:17:40 PM ******/
CREATE NONCLUSTERED INDEX [nclxActive_LineItems_CurrentTermStarDate] ON [dbo].[Active_LineItems]
(
	[CurrentTermStartDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [nclxActive_LineItems_RenewalDate]    Script Date: 1/29/2018 3:17:40 PM ******/
CREATE NONCLUSTERED INDEX [nclxActive_LineItems_RenewalDate] ON [dbo].[Active_LineItems]
(
	[RenewalDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
