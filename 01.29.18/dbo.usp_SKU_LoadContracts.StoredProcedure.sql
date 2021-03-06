USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_SKU_LoadContracts]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_SKU_LoadContracts] 
@ProcessingFlg Char(1)='U'
AS

TRUNCATE TABLE [dbo].[Contract_Input_List]; 

INSERT [dbo].[Contract_Input_List] (ContractID,[BundleFlg])
SELECT ContractID, [BundleFlg] FROM  [dbo].[ProcessedContracts] WHERE [StatusFlg] = @ProcessingFlg;

GO
