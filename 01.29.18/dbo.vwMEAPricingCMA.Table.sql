USE [RevPro]
GO
/****** Object:  Table [dbo].[vwMEAPricingCMA]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[vwMEAPricingCMA](
	[MEA] [varchar](100) NOT NULL,
	[MEAContractID] [int] NULL,
	[ContractID] [int] NULL,
	[MEAContractComponentID] [int] NULL,
	[ComponentType] [varchar](50) NULL,
	[ComponentID] [int] NULL,
	[SKU] [varchar](100) NULL,
	[ComponentPrice] [decimal](15, 2) NULL,
	[DerivedProductID] [int] NULL,
	[ProductSubTypeID] [int] NULL,
	[ProductSubTypeText] [varchar](100) NULL,
	[LineItemCount] [int] NOT NULL,
	[IndustrialSqFt] [decimal](15, 2) NULL,
	[UnitCount] [decimal](15, 2) NULL,
	[RetailSqFt] [decimal](15, 2) NULL,
	[OfficeSqFt] [decimal](15, 2) NULL,
	[MarketsWithNoProperties] [decimal](15, 2) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
