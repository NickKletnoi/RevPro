USE [RevPro]
GO
/****** Object:  StoredProcedure [dbo].[uspSKUnb]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspSKUnb]
@CONTRACTID INT
AS

BEGIN TRY

DECLARE @CURRENT_DateID  VARCHAR(10)
DECLARE @CURRENT_SKUID INT
DECLARE @CURRENT_LIST_PRICE MONEY
DECLARE @EXISTING_SKUID INT
DECLARE @SKU_EXISTS INT
DECLARE @PROCEDURE_NAME VARCHAR(150)='dbo.uspSKUnb'
DECLARE @VARIABLE_VALUES VARCHAR(8000)

	SELECT DISTINCT Convert(varchar(10),[Date],101) AS DATE2
		INTO #DateList 
			FROM LineItem 
				WHERE ContractID= @CONTRACTID
				     AND BundleID IS NULL

	SET @CURRENT_DateID = NULL

	SELECT TOP 1 @CURRENT_DateID = DATE2  
			FROM #DateList

   	WHILE (@CURRENT_DateID IS NOT NULL)
	
	 BEGIN
				
				SELECT BundleID, ProductID,MarketID,UserCount,CustomerType,Date AS Date2,Amount
				INTO #Dates 
					FROM   LineItem
						WHERE  Convert(varchar(10),[Date],101)
						=@CURRENT_DateID AND ContractID=@CONTRACTID;

             			
				SELECT 

				@SKU_EXISTS=COUNT(*),
				@EXISTING_SKUID=S.SKUID
				
				FROM #Dates D JOIN Sku S 
					ON D.ProductID=S.ProductID 
						AND D.MarketID=S.MarketID 
							AND D.UserCount=S.UserCount
							   AND D.CustomerType=S.CustomerType

				GROUP BY S.SKUID

				IF @SKU_EXISTS>0 
				   BEGIN 
				   
				         SET  @CURRENT_SKUID=@EXISTING_SKUID
						
						 UPDATE LI

				         SET LI.SKUID=@CURRENT_SKUID

							FROM LineItem LI JOIN Sku S 
								ON S.ProductID=LI.ProductID 
									AND  S.MarketID=LI.MarketID 
										AND S.UserCount=LI.UserCount
										   AND S.CustomerType=LI.CustomerType
											 AND LI.ContractID=@CONTRACTID
												AND 
												Convert(varchar(10),LI.[Date],101)
												=@CURRENT_DateID
				 
                       
					      UPDATE SP

						  SET SP.Price=@CURRENT_LIST_PRICE,
						      SP.AuditDate=GETDATE(),
						      SP.LastUpdateDate=GETDATE()
						  FROM SkuPrice SP
						  WHERE SP.SKUID=@CURRENT_SKUID						
							   
				 END
								
				ELSE 
				
				BEGIN
			
				SET  @CURRENT_SKUID=NULL

				SELECT @CURRENT_SKUID=COUNT(*) 
					FROM [Sku]
								
				INSERT [Sku] (SKUID,ProductID,MarketID,UserCount,CustomerType,Date,Amount,AuditDate)
				SELECT @CURRENT_SKUID, ProductID,MarketID,UserCount,CustomerType,Date2,Amount,GETDATE() 
					FROM #Dates 
						WHERE Date2=@CURRENT_DateID
						            
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
										 AND Convert(varchar(10),LI.[Date],101)
										 =@CURRENT_DateID
	           

				END	
		
		DELETE 
			FROM #DateList 
				WHERE DATE2 = @CURRENT_DateID
		DROP TABLE  #Dates
		SET @CURRENT_DateID = NULL
		SELECT TOP 1 @CURRENT_DateID = DATE2  
			FROM #DateList
		IF @@ROWCOUNT = 0 SET @CURRENT_DateID = NULL
   END 

Update PC
SET PC.[StatusFlg]='Y'
FROM [dbo].[ProcessedContracts] PC WHERE [ContractID]=@CONTRACTID

END TRY

BEGIN CATCH
         -------------ERROR HANDLING AREA----------------------------------------------------------------------------------------------
		 DECLARE @ERROR_MSG VARCHAR(8000)
		 SET @ERROR_MSG = ERROR_MESSAGE()
		 SET @VARIABLE_VALUES = 'ContractID:' + CAST(@CONTRACTID AS VARCHAR(20)) + ' / SKUID:' + CAST(@CURRENT_SKUID AS VARCHAR(20))
		 INSERT [dbo].[SkuError] ([ProcedureName],[ProcessingLogicUsed],[ErrorMessage],[VariableValues],[AuditDate])
		 SELECT @PROCEDURE_NAME,'Bundle DOES NOT Exist', @ERROR_MSG, @VARIABLE_VALUES, GETDATE()
		 --------------------------------------------------------------------------------------------------------------------------------
 
END CATCH






GO
