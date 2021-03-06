USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[usp_SKU_GetContractList]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_SKU_GetContractList] 
AS


----------  Main Part Starts Here  -----------------------------------------------------------
INSERT dbo.[ProcessedContracts](ContractID,BundleFlg,StatusFlg)
SELECT distinct contractid , 
CASE WHEN COALESCE(BundleID,[dbo].[fnGetMaxBundle](ContractID)) IS NOT NULL  THEN 'Y' ELSE 'N' END AS BundleFlg,'U' 
FROM Staging..LineItem WHERE ContractID not in (
SELECT distinct contractid from dbo.ProcessedContracts) 
AND LineItemStatusID=1

------------------------- Comment this secttion in/out as needed for Testing/Real Deal -------------
--AND ContractID IN (
--188871,
--186962,
--184147,
--188434,
--184704,
--187917,
--185327,
--180502,
--186551
--);

Update P SET P.StatusFlg='U', P.[StatusDateTime]=GETDATE() from dbo.ProcessedContracts P WHERE P.StatusFlg IS NULL; 

-----------------------  check for dups and make sure there are none -------------------

WITH dups as (
select contractID, ROW_NUMBER() OVER (PARTITION BY ContractID ORDER BY StatusFlg) as rn
from dbo.ProcessedContracts
)
delete from dups where rn>1;








GO
