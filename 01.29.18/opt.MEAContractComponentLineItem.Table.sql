USE [RevPro]
GO
/****** Object:  Table [opt].[MEAContractComponentLineItem]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [opt].[MEAContractComponentLineItem](
	[MEAContractComponentLineItemID] [int] NOT NULL,
	[MEAContractComponentID] [int] NOT NULL,
	[LineItemID] [int] NOT NULL,
	[IsFreeIgnoredFlag] [bit] NOT NULL
) ON [PRIMARY]

GO
