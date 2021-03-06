USE [RevPro]
GO
/****** Object:  Table [lookups].[EquivalentSalesUnit]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [lookups].[EquivalentSalesUnit](
	[EquivalentSalesUnitID] [int] NOT NULL,
	[ProductID] [int] NOT NULL,
	[SalesUnitID] [int] NOT NULL,
	[SalesUnitDesc] [varchar](100) NOT NULL,
	[IsSameAsProductID] [int] NOT NULL,
	[IsSameAsSalesUnitID] [int] NOT NULL,
	[IsSameAsSalesUnitDesc] [varchar](100) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
