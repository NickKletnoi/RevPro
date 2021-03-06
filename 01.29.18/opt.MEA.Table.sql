USE [RevPro]
GO
/****** Object:  Table [opt].[MEA]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [opt].[MEA](
	[MEA] [varchar](100) NOT NULL,
	[MEAType] [varchar](100) NOT NULL,
	[MEALevel] [int] NULL,
	[MonthlyDiscountedPrice] [decimal](15, 2) NULL,
	[MonthlyListPriceFromComponents] [decimal](15, 2) NULL,
	[MonthlyListPriceFromSalesOrders] [decimal](15, 2) NULL,
	[InitialTotalExtendedPrice] [decimal](15, 2) NULL,
	[InitialTotalExtendedListPrice] [decimal](15, 2) NULL,
	[FinalTotalExtendedPrice] [decimal](15, 2) NULL,
	[BilledTotalExtendedPrice] [decimal](15, 2) NULL,
	[IsReadyToTransferFlag] [bit] NULL,
	[MEAStartDate] [date] NULL,
	[MEAAdjustedStartDate] [date] NULL,
	[MEAAdjustedEndDate] [date] NULL,
	[MEABillingStartDate] [date] NULL,
	[MEAInitialExpectedEndDate] [date] NULL,
	[MEAEndDate] [date] NULL,
	[MEAInitialWholeMonths] [int] NULL,
	[MEAActualWholeMonthsAtEnd] [int] NULL,
	[RevenueRunID] [int] NOT NULL,
	[MEARuleStartDate] [date] NULL,
	[MEATermMonths] [int] NULL,
	[ParentMEA] [varchar](100) NULL,
	[PriorMEA] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
