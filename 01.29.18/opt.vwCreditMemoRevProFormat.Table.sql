USE [RevPro]
GO
/****** Object:  Table [opt].[vwCreditMemoRevProFormat]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [opt].[vwCreditMemoRevProFormat](
	[RevProFormattedOutput] [varchar](8000) NULL,
	[DEAL_ID] [varchar](100) NULL,
	[ITEM_ID] [varchar](100) NULL,
	[RecordDate] [varchar](8000) NULL,
	[AdjustedEventYear] [int] NULL,
	[AdjustedEventMonth] [int] NULL,
	[RevenueRunID] [int] NOT NULL,
	[TRAN_TYPE] [varchar](20) NULL,
	[ext_SELL_PRICE] [decimal](20, 2) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
