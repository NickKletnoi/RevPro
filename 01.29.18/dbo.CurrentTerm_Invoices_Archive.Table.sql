USE [RevPro]
GO
/****** Object:  Table [dbo].[CurrentTerm_Invoices_Archive]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CurrentTerm_Invoices_Archive](
	[RowID] [int] NOT NULL,
	[ContractID] [int] NOT NULL,
	[LineItemID] [int] NOT NULL,
	[CurrentTermStartDate] [date] NULL,
	[RenewalDate] [date] NULL,
	[BillingStartDate] [date] NULL,
	[Line Item ID] [int] NOT NULL,
	[Posting Date] [datetime] NOT NULL,
	[Shipment Date] [datetime] NOT NULL,
	[Document No_] [varchar](20) NOT NULL,
	[Line No_] [int] NOT NULL,
	[Amount] [decimal](38, 20) NOT NULL,
	[RULE_START_DATE] [datetime] NULL,
	[RULE_END_DATE] [datetime] NULL,
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
	[RunPeriod] [datetime] NOT NULL,
	[RunDate] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
