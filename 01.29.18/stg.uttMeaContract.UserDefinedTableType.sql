USE [RevPro]
GO
/****** Object:  UserDefinedTableType [stg].[uttMeaContract]    Script Date: 1/29/2018 3:17:38 PM ******/
CREATE TYPE [stg].[uttMeaContract] AS TABLE(
	[MEAContractID] [int] NULL,
	[MEA] [varchar](100) NULL,
	[ContractID] [int] NULL
)
GO
