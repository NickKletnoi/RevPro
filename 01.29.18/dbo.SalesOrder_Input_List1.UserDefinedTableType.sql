USE [RevPro]
GO
/****** Object:  UserDefinedTableType [dbo].[SalesOrder_Input_List1]    Script Date: 1/29/2018 3:17:38 PM ******/
CREATE TYPE [dbo].[SalesOrder_Input_List1] AS TABLE(
	[SalesOrderID] [int] NULL,
	[BatchID] [int] NULL
)
GO
