USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_SKU_MSTR]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_SKU_MSTR] 
AS
EXEC [dbo].[usp_SKU_GetContractList];
EXEC [dbo].[usp_SKU_LoadContracts];
EXEC [dbo].[usp_SKU_LoadLineItem];  
EXEC [dbo].[usp_SKU_ProcessContracts]; 
EXEC [dbo].[usp_SKU_Cleanup];




GO
