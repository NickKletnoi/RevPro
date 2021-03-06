USE [RevPro]
GO
/****** Object:  Table [lookups].[ProductNetworkMapping]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [lookups].[ProductNetworkMapping](
	[ProductID] [int] NOT NULL,
	[EquivalentProductID] [int] NOT NULL,
	[DerivedProductID] [int] NOT NULL,
	[DerivedProductName] [varchar](100) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
