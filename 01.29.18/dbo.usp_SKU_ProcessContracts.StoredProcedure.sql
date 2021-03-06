USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_SKU_ProcessContracts]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_SKU_ProcessContracts]
AS

DECLARE @CURRENT_CONTRACTID INT
DECLARE @BUNDLE_FLG CHAR(1)

 DECLARE C CURSOR FOR
 SELECT [ContractID],ISNULL([BundleFlg],'Y') BundleFlg FROM [dbo].[Contract_Input_List]  ORDER BY [ContractID]
  
 OPEN C
 FETCH C INTO @CURRENT_CONTRACTID, @BUNDLE_FLG
 WHILE @@FETCH_STATUS = 0
 BEGIN
					  	IF  @BUNDLE_FLG='Y' BEGIN  EXEC [dbo].[uspSKU] @CURRENT_CONTRACTID  END 
						IF  @BUNDLE_FLG='N' BEGIN  EXEC [dbo].[uspSKUnb] @CURRENT_CONTRACTID  END 

						      UPDATE CIL SET CIL.StatusFlg='P', CIL.AuditDate=GETDATE() 
			                  FROM [dbo].[Contract_Input_List] CIL 
				              WHERE CIL.ContractID=@CURRENT_CONTRACTID;

							  UPDATE PC
							  SET PC.StatusFlg='P', PC.StatusDateTime=GETDATE()
							  FROM dbo.ProcessedContracts PC 
							  WHERE PC.ContractID=@CURRENT_CONTRACTID;

FETCH C INTO @CURRENT_CONTRACTID, @BUNDLE_FLG
END

 CLOSE C
 DEALLOCATE C




GO
