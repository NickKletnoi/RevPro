USE [RevPro]
GO
/****** Object:  Table [stg].[Contract_Input_List]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [stg].[Contract_Input_List](
	[ContractID] [int] NOT NULL,
	[StatusFlg] [varchar](1) NOT NULL,
	[AuditDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
