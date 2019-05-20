USE [RevPro]
GO
/****** Object:  Table [dbo].[LineItem]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[LineItem](
	[LineItemID] [int] NOT NULL,
	[ContractID] [int] NOT NULL,
	[BundleID] [int] NULL,
	[ProductID] [int] NOT NULL,
	[MarketID] [varchar](20) NOT NULL,
	[UserCount] [int] NOT NULL,
	[CustomerType] [int] NOT NULL,
	[Date] [smalldatetime] NULL,
	[SKUID] [int] NOT NULL,
	[DiscountedMonthlyPrice] [decimal](10, 2) NULL,
	[OriginalMonthlyPrice] [decimal](10, 2) NULL,
	[Amount] [decimal](10, 2) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
