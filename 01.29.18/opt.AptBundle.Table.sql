USE [RevPro]
GO
/****** Object:  Table [opt].[AptBundle]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [opt].[AptBundle](
	[AptBundleID] [int] NOT NULL,
	[PropertyID] [int] NOT NULL,
	[DerivedProductID] [int] NOT NULL,
	[EquivalentProductID] [int] NOT NULL,
	[ContractLocationID] [int] NOT NULL,
	[StartDate] [date] NOT NULL,
	[EndDate] [nchar](10) NOT NULL,
	[MEA] [varchar](100) NULL,
	[AptBundleDesc] [varchar](100) NULL,
	[HasPromo] [bit] NOT NULL,
	[RevenueRunID] [int] NOT NULL,
	[DerivedProductName] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
