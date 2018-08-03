USE [RevPro]
GO
/****** Object:  Table [bal].[2017BalancesContractLineItem]    Script Date: 1/29/2018 3:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [bal].[2017BalancesContractLineItem](
	[ContractID] [int] NOT NULL,
	[LineItemID] [int] NULL,
	[TotalAmount] [decimal](38, 20) NULL,
	[SKUID] [int] NULL
) ON [PRIMARY]

GO
