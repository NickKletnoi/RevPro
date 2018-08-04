USE [RevPro]
GO
/****** Object:  Table [dbo].[BusinessType]    Script Date: 1/29/2018 3:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BusinessType](
	[BusinessTypeID] [int] NULL,
	[BusinessTypeCategoryID] [int] NULL,
	[BusinessTypeName] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
