USE [RevPro]
GO
/****** Object:  Table [lookups].[CarveInRevenue]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [lookups].[CarveInRevenue](
	[ProductID] [int] NOT NULL,
	[DerivedProductID] [int] NULL,
	[CarveInOut] [int] NULL
) ON [PRIMARY]

GO
