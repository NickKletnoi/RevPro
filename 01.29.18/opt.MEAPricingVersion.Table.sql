USE [RevPro]
GO
/****** Object:  Table [opt].[MEAPricingVersion]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [opt].[MEAPricingVersion](
	[MEAPricingVersionID] [int] NOT NULL,
	[MEA] [varchar](100) NOT NULL,
	[ContractID] [int] NOT NULL,
	[SequenceNumber] [int] NOT NULL,
	[StartDate] [date] NOT NULL,
	[EndDate] [nchar](10) NOT NULL,
	[TotalPrice] [decimal](15, 2) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
