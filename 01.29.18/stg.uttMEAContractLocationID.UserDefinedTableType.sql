USE [RevPro]
GO
/****** Object:  UserDefinedTableType [stg].[uttMEAContractLocationID]    Script Date: 1/29/2018 3:17:39 PM ******/
CREATE TYPE [stg].[uttMEAContractLocationID] AS TABLE(
	[MEAContractID] [int] NULL,
	[LocationID] [int] NULL
)
GO
