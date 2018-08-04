USE [RevPro]
GO
/****** Object:  Table [lookups].[GenProdPostingGroup]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [lookups].[GenProdPostingGroup](
	[ProductID] [int] NOT NULL,
	[DerivedProductID] [int] NULL,
	[GenProdGroup] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
