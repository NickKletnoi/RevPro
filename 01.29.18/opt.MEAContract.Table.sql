USE [RevPro]
GO
/****** Object:  Table [opt].[MEAContract]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [opt].[MEAContract](
	[MEAContractID] [int] NOT NULL,
	[MEA] [varchar](100) NOT NULL,
	[ContractID] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
