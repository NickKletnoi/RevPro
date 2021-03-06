USE [RevPro]
GO
/****** Object:  Table [dbo].[RevPro_GL_Mapping]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RevPro_GL_Mapping](
	[ProductID] [int] NOT NULL,
	[ProductName] [varchar](100) NULL,
	[ProductDesc] [varchar](100) NULL,
	[Gen_ProdPosting_Group] [varchar](100) NULL,
	[LT_Deferred_Account_Seg1] [varchar](100) NULL,
	[LT_Deferred_Account_Seg3] [varchar](100) NULL,
	[LT_Deferred_Account_Seg4] [varchar](100) NULL,
	[LT_Deferred_Account_Seg5] [varchar](100) NULL,
	[Carve_IN_Def_Revenue_Seg1] [varchar](100) NULL,
	[Carve_IN_Def_Revenue_Seg3] [varchar](100) NULL,
	[Carve_IN_Def_Revenue_Seg4] [varchar](100) NULL,
	[Carve_IN_Def_Revenue_Seg5] [varchar](100) NULL,
	[Unbilled_AR_Seg1] [varchar](100) NULL,
	[Unbilled_AR_Seg3] [varchar](100) NULL,
	[Unbilled_AR_Seg4] [varchar](100) NULL,
	[Unbilled_AR_Seg5] [varchar](100) NULL,
	[Carve_IN_Revenue_Seg1] [varchar](100) NULL,
	[Carve_IN_Revenue_Seg3] [varchar](100) NULL,
	[Carve_IN_Revenue_Seg4] [varchar](100) NULL,
	[Carve_IN_Revenue_Seg5] [varchar](100) NULL,
	[Carve_OUT_Revenue_Seg1] [varchar](100) NULL,
	[Carve_OUT_Revenue_Seg3] [varchar](100) NULL,
	[Carve_OUT_Revenue_Seg4] [varchar](100) NULL,
	[Carve_OUT_Revenue_Seg5] [varchar](100) NULL,
	[Def_Acctg_Seg1] [varchar](100) NULL,
	[Def_Acctg_Seg3] [varchar](100) NULL,
	[Def_Acctg_Seg4] [varchar](100) NULL,
	[Def_Acctg_Seg5] [varchar](100) NULL,
	[Rev_Acctg_Seg1] [varchar](100) NULL,
	[Rev_Acctg_Seg3] [varchar](100) NULL,
	[Rev_Acctg_Seg4] [varchar](100) NULL,
	[Rev_Acctg_Seg5] [varchar](100) NULL,
	[Active_Fl] [int] NULL,
	[Create_DT] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Index [clxProductID]    Script Date: 1/29/2018 3:17:40 PM ******/
CREATE CLUSTERED INDEX [clxProductID] ON [dbo].[RevPro_GL_Mapping]
(
	[ProductID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
