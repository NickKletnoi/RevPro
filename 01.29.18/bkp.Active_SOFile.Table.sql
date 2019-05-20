USE [RevPro]
GO
/****** Object:  Table [bkp].[Active_SOFile]    Script Date: 1/29/2018 3:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [bkp].[Active_SOFile](
	[ContractID] [int] NULL,
	[LineItemID] [int] NULL,
	[StatusFlg] [char](1) NULL,
	[AuditDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
