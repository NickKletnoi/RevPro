USE [RevPro]
GO
/****** Object:  Table [dbo].[SkuBridge]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SkuBridge](
	[LineItemID] [int] NULL,
	[SKUID] [int] NULL,
	[AuditDate] [datetime] NULL
) ON [PRIMARY]

GO
/****** Object:  Index [clxSkuBridge]    Script Date: 1/29/2018 3:17:40 PM ******/
CREATE CLUSTERED INDEX [clxSkuBridge] ON [dbo].[SkuBridge]
(
	[LineItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
