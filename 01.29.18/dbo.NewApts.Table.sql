USE [RevPro]
GO
/****** Object:  Table [dbo].[NewApts]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[NewApts](
	[SKUID] [int] NULL,
	[OldSkuName] [varchar](50) NULL,
	[NewSkuName] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
