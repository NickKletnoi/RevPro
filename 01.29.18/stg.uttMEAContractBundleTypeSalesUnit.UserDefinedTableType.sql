USE [RevPro]
GO
/****** Object:  UserDefinedTableType [stg].[uttMEAContractBundleTypeSalesUnit]    Script Date: 1/29/2018 3:17:39 PM ******/
CREATE TYPE [stg].[uttMEAContractBundleTypeSalesUnit] AS TABLE(
	[MEAContractID] [int] NULL,
	[BundleTypeSalesunitID] [int] NULL,
	[BundleTypeSalesunitDesc] [varchar](25) NULL
)
GO
