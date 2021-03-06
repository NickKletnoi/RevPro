USE [RevPro]
GO
/****** Object:  Table [dbo].[vwMEAPricingSuiteMarketPrice]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[vwMEAPricingSuiteMarketPrice](
	[MEA] [varchar](100) NOT NULL,
	[MEAContractID] [int] NULL,
	[ContractID] [int] NULL,
	[ComponentType] [varchar](50) NULL,
	[ComponentID] [int] NULL,
	[DerivedProductID] [int] NULL,
	[ProductSubTypeID] [int] NULL,
	[ProductSubTypeText] [varchar](100) NULL,
	[SKU] [varchar](100) NULL,
	[ComponentPrice] [decimal](15, 2) NULL,
	[ProductmarketTypeID] [decimal](15, 2) NULL,
	[ProductMarketDesc] [varchar](100) NULL,
	[AttributeTextValue] [varchar](100) NULL,
	[UserCount] [decimal](15, 2) NULL,
	[MarketCount] [decimal](15, 2) NULL,
	[ProductCount] [decimal](15, 2) NULL,
	[TotalEmployees] [decimal](15, 2) NULL,
	[HomeMarketID] [decimal](15, 2) NULL,
	[HomeStateCD] [varchar](100) NULL,
	[IndustryTypeGroupId] [decimal](15, 2) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
