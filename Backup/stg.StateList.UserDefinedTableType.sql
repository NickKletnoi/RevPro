USE [RevPro]
GO
/****** Object:  UserDefinedTableType [stg].[StateList]    Script Date: 1/29/2018 3:17:38 PM ******/
CREATE TYPE [stg].[StateList] AS TABLE(
	[StateCode] [char](2) NULL,
	[Statename] [varchar](50) NULL
)
GO
