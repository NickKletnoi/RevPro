USE [RevPro]
GO
/****** Object:  UserDefinedTableType [stg].[ProductProperty]    Script Date: 1/29/2018 3:17:38 PM ******/
CREATE TYPE [stg].[ProductProperty] AS TABLE(
	[ProductID] [int] NOT NULL,
	[PropertyID] [int] NOT NULL,
	[ContractTermID] [int] NULL
)
GO
