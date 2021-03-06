USE [RevPro]
GO
/****** Object:  Table [opt].[MEAContractComponent]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [opt].[MEAContractComponent](
	[MEAContractComponentID] [int] NOT NULL,
	[MEAContractID] [int] NOT NULL,
	[ComponentType] [varchar](50) NOT NULL,
	[ComponentID] [int] NOT NULL,
	[ComponentPrice] [decimal](15, 2) NOT NULL,
	[SKU] [varchar](100) NOT NULL,
	[LineItemCount] [int] NULL,
	[RevenueLineItemCount] [int] NULL,
	[DerivedProductID] [int] NOT NULL,
	[ProductSubTypeID] [int] NULL,
	[ProductSubTypeText] [varchar](100) NULL,
	[CompenentExpectedStartDate] [date] NULL,
	[CompenentActualActiveStartDate] [date] NULL,
	[ComponentActualActiveEndDate] [date] NULL,
	[ComponentExpectedEndDate] [date] NULL,
	[ComponentActualWholeMonths] [int] NULL,
	[ComponentExpectedWholeMonths] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
