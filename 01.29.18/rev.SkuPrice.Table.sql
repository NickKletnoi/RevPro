USE [RevPro]
GO
/****** Object:  Table [rev].[SkuPrice]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [rev].[SkuPrice](
	[SKUID] [int] NULL,
	[SkuName] [varchar](150) NULL,
	[Price] [money] NULL,
	[ProductCategory] [varchar](150) NULL,
	[CustomerPricingCategory] [varchar](150) NULL,
	[ProcessingTierflg] [char](1) NULL,
	[BusinessTypeCategory] [varchar](100) NULL,
	[MarketName] [varchar](150) NULL,
	[LastUpdateDate] [date] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
