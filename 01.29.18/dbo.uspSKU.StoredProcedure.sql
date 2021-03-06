USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[uspSKU]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspSKU]
@CONTRACTID INT
AS

BEGIN TRY

DECLARE @CURRENT_BundleID  INT
DECLARE @CURRENT_SKUID INT
DECLARE @CURRENT_LIST_PRICE MONEY
DECLARE @EXISTING_SKUID INT
DECLARE @SKU_EXISTS INT
DECLARE @PROCEDURE_NAME VARCHAR(150)='dbo.uspSKU'
DECLARE @VARIABLE_VALUES VARCHAR(8000)


	SELECT DISTINCT BUNDLEID 
		INTO #BundleList 
			FROM LineItem 
				WHERE ContractID= @CONTRACTID
				     AND SKUID=-1

	SET @CURRENT_BundleID = NULL

	SELECT TOP 1 @CURRENT_BundleID = BUNDLEID  
			FROM #BundleList

	WHILE (@CURRENT_BundleID IS NOT NULL)
	
	 BEGIN
				
				SELECT BundleID, ProductID,MarketID,UserCount,CustomerType,Date,Amount
				INTO   #Bundles
					FROM   LineItem
						WHERE  BundleID=@CURRENT_BundleID 
				
				SELECT 

				@SKU_EXISTS=COUNT(*),
				@EXISTING_SKUID=S.SKUID
				
				FROM #Bundles B JOIN Sku S 
					ON B.ProductID=S.ProductID 
						AND B.MarketID=S.MarketID 
							AND B.UserCount=S.UserCount
							   AND B.CustomerType=S.CustomerType

				GROUP BY S.SKUID

				IF @SKU_EXISTS>0 
				   BEGIN 
				   
				         SET  @CURRENT_SKUID=@EXISTING_SKUID 
						 SELECT @CURRENT_LIST_PRICE=SUM(Amount) from #Bundles B
											WHERE B.BundleID = @CURRENT_BundleID

						 UPDATE LI

				         SET LI.SKUID=@CURRENT_SKUID

							FROM LineItem LI JOIN Sku S 
								ON S.ProductID=LI.ProductID 
									AND  S.MarketID=LI.MarketID 
										AND S.UserCount=LI.UserCount
										   AND S.CustomerType=LI.CustomerType
											 AND LI.ContractID=@CONTRACTID
												AND LI.BundleID=@CURRENT_BundleID
                       
					      UPDATE SP

						  SET SP.Price=@CURRENT_LIST_PRICE,
						      SP.LastUpdateDate=GETDATE(),
							  SP.AuditDate=GETDATE()
						  FROM SkuPrice SP
								WHERE SP.SKUID=@CURRENT_SKUID						
							   
				   END
								
				ELSE 
				
				BEGIN
			
				SET  @CURRENT_SKUID=NULL

				SELECT @CURRENT_SKUID=COUNT(*) 
					FROM [Sku]
								
				INSERT [Sku] (SKUID,ProductID,MarketID,UserCount,CustomerType,Date,Amount,AuditDate)
				SELECT @CURRENT_SKUID, ProductID,MarketID,UserCount,CustomerType,Date,Amount,GETDATE() 
					FROM #Bundles 
						WHERE BundleID=@CURRENT_BundleID
						            
                INSERT SkuPrice (SKUID,Price,AuditDate)
				SELECT SKUID, SUM(AMOUNT),GETDATE()
				      FROM Sku 
					     WHERE SKUID=@CURRENT_SKUID
					      GROUP BY SKUID;

                 UPDATE SP
				    SET SP.LastUpdateDate=GETDATE(),
					    SP.AuditDate=GETDATE()
					   FROM SkuPrice SP
					      WHERE SKUID=@CURRENT_SKUID
				  
				
				UPDATE LI
				SET LI.SKUID=S.SKUID
					FROM LineItem LI JOIN Sku S 
						ON S.ProductID=LI.ProductID 
							AND S.MarketID=LI.MarketID 
								AND S.UserCount=LI.UserCount
								   AND S.CustomerType=LI.CustomerType
									  AND LI.ContractID=@CONTRACTID 
										 AND LI.BundleID=@CURRENT_BundleID
	           

				END	
		
		DELETE 
			FROM #BundleList 
				WHERE BundleID = @CURRENT_BundleID

		DROP TABLE  #Bundles

		SET @CURRENT_BundleID = NULL

		SELECT TOP 1 @CURRENT_BundleID = BundleID  
			FROM #BundleList

		IF @@ROWCOUNT = 0 SET @CURRENT_BundleID = NULL
   END 

Update PC
SET PC.[StatusFlg]='Z'
FROM [dbo].[ProcessedContracts] PC WHERE [ContractID]=@CONTRACTID

END TRY

BEGIN CATCH
         -------------ERROR HANDLING AREA---------------------------------------------------------------------------------------
		 DECLARE @ERROR_MSG VARCHAR(8000)
		 SET @ERROR_MSG = ERROR_MESSAGE()
		 SET @VARIABLE_VALUES = 'ContractID:' + CAST(@CONTRACTID AS VARCHAR(20)) + ' / SKUID:' + CAST(@CURRENT_SKUID AS VARCHAR(20))
		 INSERT [dbo].[SkuError] ([ProcedureName],[ProcessingLogicUsed],[ErrorMessage],[VariableValues],[AuditDate])
		 SELECT @PROCEDURE_NAME,'Bundle Exists', @ERROR_MSG, @VARIABLE_VALUES, GETDATE()
         ---------------------------------------------------------------------------------------------------------------------
END CATCH






GO
