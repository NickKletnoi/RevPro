USE [RevPro]
GO
/****** Object:  Table [dbo].[ProcessedContracts]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ProcessedContracts](
	[ContractID] [int] NULL,
	[StatusFlg] [char](1) NULL,
	[StatusDateTime] [datetime] NULL,
	[BundleFlg] [char](1) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Index [IDX_PC_C]    Script Date: 1/29/2018 3:17:40 PM ******/
CREATE NONCLUSTERED INDEX [IDX_PC_C] ON [dbo].[ProcessedContracts]
(
	[ContractID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
