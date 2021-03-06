USE [RevPro]
GO
/****** Object:  Table [dbo].[SkuError]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SkuError](
	[ProcedureName] [varchar](150) NULL,
	[ProcessingLogicUsed] [varchar](150) NULL,
	[ErrorMessage] [varchar](8000) NULL,
	[VariableValues] [varchar](8000) NULL,
	[AuditDate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
