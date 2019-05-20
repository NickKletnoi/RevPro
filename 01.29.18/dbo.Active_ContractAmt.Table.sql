USE [RevPro]
GO
/****** Object:  Table [dbo].[Active_ContractAmt]    Script Date: 1/29/2018 3:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Active_ContractAmt](
	[ContractID] [int] NULL,
	[Amount] [int] NULL,
	[LastInquiredDate] [date] NULL,
	[flg] [char](1) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
