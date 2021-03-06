USE [RevPro]
GO
/****** Object:  StoredProcedure [opt].[spProcessSalesOrder]    Script Date: 1/29/2018 3:17:40 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [opt].[spProcessSalesOrder]
 (@pContractLocationID int = null, @pDebug bit = 0, @pRevenueRunID int )
AS
	
INSERT  [opt].[RevenueItemProcessed]
       (
	   [DEAL_ID]
      ,[CARVE_IN_DEF_REVENUE_SEG1]
      ,[CARVE_IN_DEF_REVENUE_SEG3]
      ,[CARVE_IN_DEF_REVENUE_SEG4]
      ,[UNBILLED_AR_SEG1]
      ,[UNBILLED_AR_SEG3]
      ,[UNBILLED_AR_SEG4]
      ,[CARVE_IN_REVENUE_SEG1]
      ,[CARVE_IN_REVENUE_SEG3]
      ,[CARVE_IN_REVENUE_SEG4]
      ,[CARVE_OUT_REVENUE_SEG1]
      ,[CARVE_OUT_REVENUE_SEG3]
      ,[CARVE_OUT_REVENUE_SEG4]
      ,[ATTRIBUTE24]
      ,[ATTRIBUTE26]
      ,[ATTRIBUTE27]
      ,[BASE_CURR_CODE]
      ,[BILL_TO_COUNTRY]
      ,[BILL_TO_CUSTOMER_NAME]
      ,[BILL_TO_CUSTOMER_NUMBER]
      ,[BUSINESS_UNIT]
      ,[CUSTOMER_ID]
      ,[CUSTOMER_NAME]
      ,[DEF_ACCTG_SEG1]
      ,[DEF_ACCTG_SEG3]
      ,[DEF_ACCTG_SEG4]
      ,[DEFERRED_REVENUE_FLAG]
      ,[ELIGIBLE_FOR_CV]
      ,[ELIGIBLE_FOR_FV]
      ,[EX_RATE]
      ,[EXT_LIST_PRICE]
      ,[EXT_SELL_PRICE]
      ,[FLAG_97_2]
      ,[INVOICE_DATE]
      ,[INVOICE_ID]
      ,[INVOICE_LINE]
      ,[INVOICE_NUMBER]
      ,[INVOICE_TYPE]
      ,[ITEM_DESC]
      ,[ITEM_ID]
      ,[ITEM_NUMBER]
      ,[LT_DEFERRED_ACCOUNT]
      ,[NON_CONTINGENT_FLAG]
      ,[ORDER_LINE_TYPE]
      ,[ORDER_TYPE]
      ,[ORG_ID]
      ,[ORIG_INV_LINE_ID]
      ,[PCS_FLAG]
      ,[PO_NUM]
      ,[PRODUCT_CATEGORY]
      ,[PRODUCT_CLASS]
      ,[PRODUCT_FAMILY]
      ,[PRODUCT_LINE]
      ,[QUANTITY_INVOICED]
      ,[QUANTITY_ORDERED]
      ,[QUANTITY_SHIPPED]
      ,[QUOTE_NUM]
      ,[RCURR_EX_RATE]
      ,[RETURN_FLAG]
      ,[REV_ACCTG_SEG1]
      ,[REV_ACCTG_SEG3]
      ,[REV_ACCTG_SEG4]
      ,[RULE_END_DATE]
      ,[RULE_START_DATE]
      ,[SALES_ORDER]
      ,[SALES_ORDER_ID]
	  ,[SALES_ORDER_LINE_ID]
	  ,[SALESREP_NAME]
	  ,[SALES_REP_ID]
      ,[SEC_ATTR_VALUE]
      ,[SO_BOOK_DATE]
      ,[STANDALONE_FLAG]
      ,[STATED_FLAG]
	   ,STUB_AMOUNT
	  ,STUB_AMOUNT_LISTPRICE
      ,[TRAN_TYPE]
      ,[TRANS_CURR_CODE]
      ,[TRANS_DATE]
      ,[UNBILLED_ACCOUNTING_FLAG]
      ,[UNDELIVERED_FLAG]
      ,[UNIT_LIST_PRICE]
      ,[UNIT_SELL_PRICE]
      ,[FV_YEAR]
	  ,RevenueRunID
	  ,SOB_ID
	  ,DerivedSalesUnitID
	  , CoStarBrandID 
	  , AdjustedEventYear
	  , AdjustedEventMonth
	  ,IsCorrectingEntry
       )

  SELECT DISTINCT  
     ISNULL(l.[MEA],'')   as    DEAL_ID
	,'2281'               as    CARVE_IN_DEF_REVENUE_SEG1		
	,'SAL'                as	CARVE_IN_DEF_REVENUE_SEG3		
	,dpd.GenProdGroup      as 	CARVE_IN_DEF_REVENUE_SEG4		
	,'1125'               as 	UNBILLED_AR_SEG1		
	,'SAL'                as 	UNBILLED_AR_SEG3		
	,dpd.GenProdGroup      as    UNBILLED_AR_SEG4		
	,crd.CarveInOut        as    CARVE_IN_REVENUE_SEG1		
	,'SAL'                as 	CARVE_IN_REVENUE_SEG3		
	,dpd.GenProdGroup      as 	CARVE_IN_REVENUE_SEG4		
	,crd.CarveInOut          as 	CARVE_OUT_REVENUE_SEG1		
	,'SAL'                as 	CARVE_OUT_REVENUE_SEG3		
	,dpd.GenProdGroup      as    CARVE_OUT_REVENUE_SEG4		
    ,CASE WHEN [IsMajor]=0   THEN 'N' ELSE 'Y'  END  ATTRIBUTE24
	,'SAL'                 as 	ATTRIBUTE26
	,dpd.GenProdGroup       as 	ATTRIBUTE27
	,[MonetaryUnitCode]    as BASE_CURR_CODE
	,l.[CountryCode]       as BILL_TO_COUNTRY
	,[BillingLocationName] as BILL_TO_CUSTOMER_NAME
	,l.[BillingLocationID] as BILL_TO_CUSTOMER_NUMBER
	,CoStarBrandCode       as  BUSINESS_UNIT--CASE WHEN l.CurrentSku like '%NET%' THEN 'APTS' ELSE b.costarBrandName  END   as BUSINESS_UNIT
	,l.[SiteLocationID]    as CUSTOMER_ID
	,[SiteLocationName]    as  CUSTOMER_NAME
	,'2280'                as  DEF_ACCTG_SEG1
   ,'SAL'                  as  DEF_ACCTG_SEG3
    ,dpd.GenProdGroup      as  DEF_ACCTG_SEG4
    ,'Y'                   as  DEFERRED_REVENUE_FLAG
	,CASE WHEN CAST(mm.MEAStartDate  as Date) <'01/01/2016' THEN 'N' ELSE 'Y' END  ELIGIBLE_FOR_CV
    ,CASE WHEN CAST(mm.MEAStartDate  as Date) <'01/01/2016' THEN 'N' ELSE 'Y' END  ELIGIBLE_FOR_FV
	,1                             as EX_RATE
	,l.EXT_AMOUNT_LISTPRICE                            as EXT_LIST_PRICE
    ,l.EXT_AMOUNT                           as EXT_SELL_PRICE   --l.DiscountedMonthlyPrice
	,'N'                           as FLAG_97_2
    ,''                            as INVOICE_DATE
    ,''                            as INVOICE_ID
    ,''                            as INVOICE_LINE
	,''                            as [INVOICE_NUMBER]
    ,''                             as INVOICE_TYPE
    ,l.[DerivedProductName]       as ITEM_DESC
	,l.[DerivedProductID]         as ITEM_ID
	,l.CurrentSKU                  as ITEM_NUMBER
	,'2282'                        as LT_DEFERRED_ACCOUNT
	,'N'                           as NON_CONTINGENT_FLAG
	,''                            as ORDER_LINE_TYPE
	,''                            as ORDER_TYPE
    ,l.[CoStarBrandID]             as ORG_ID	
    ,''                            as [ORIG_INV_LINE_ID]           
	,'N'                           as [PCS_FLAG]
    ,''                            as [PO_NUM]
	,l.[LineItemTypeID]           as PRODUCT_CATEGORY
	,2             as PRODUCT_CLASS
	,l.[DerivedProductName]       as PRODUCT_FAMILY
    ,l.[DerivedProductName]       as PRODUCT_LINE
	,''                            as QUANTITY_INVOICED
    , QUANTITY_ORDERED as 	QUANTITY_ORDERED
	, QUANTITY_ORDERED as QUANTITY_SHIPPED
    ,''                            as QUOTE_NUM
    ,1                             as RCURR_EX_RATE
	,'N'                           as RETURN_FLAG
    ,rad.REVACCTGSEG1  as REV_ACCTG_SEG1
    ,'SAL'                         as REV_ACCTG_SEG3
    ,dpd.GenProdGroup  as REV_ACCTG_SEG4
	,Cast(l.RenewalDate as Date) as RULE_END_DATE
    ,CASE WHEN DAY(l.CurrentTermStartDate)>1 THEN  DATEADD(MONTH, DATEDIFF(MONTH, '19000101', l.CurrentTermStartDate) + 1, '19000101') 
		ELSE l.CurrentTermStartDate END RULE_START_DATE
    ,l.ContractID                 as SALES_ORDER
    ,l.[ContractID]               as SALES_ORDER_ID
	,(((CONVERT([varchar](15),l.ContractID,(0))+'_')+CONVERT([varchar](10),[SOB_ID],(0)))+'_')+CONVERT([char](6),mm.MEAStartDate ,(112)) as SALES_ORDER_LINE
	  ,l.AEContactName [SALESREP_NAME]
	  ,l.AEContactID  [SALES_REP_ID]
	,'RIG'                                     as SEC_ATTR_VALUE
    ,cast(l.LineItemCreatedDate as Date)              as SO_BOOK_DATE
	,'N'                                       as STANDALONE_FLAG
    ,'N'                                       as STATED_FLAG
	, l.STUB_AMOUNT							as STUB_AMOUNT
	, l.STUB_AMOUNT_LISTPRICE				as STUB_AMOUNT_LISTPRICE
    ,'SO'                                      as TRAN_TYPE
	,[MonetaryUnitCode]                        as TRANS_CURR_CODE
	,cast(l.LineItemCreatedDate as Date)              as TRANS_DATE
	,'Y'                                       as UNBILLED_ACCOUNTING_FLAG
	,'N'                                       as UNDELIVERED_FLAG
	,ISNULL(l.ListPrice,0)    UNIT_LIST_PRICE
	 ,l.MonthlyPrice                             as UNIT_SELL_PRICE
	,YEAR(mm.MEAStartDate)			   as FV_YEAR
	, @pRevenueRunID
	,SOB_ID = l.SOB_ID
	, DerivedSalesUnitID = l.DerivedSalesUnitID
	, l.CoStarBrandID 
	, l.AdjustedEventYear
	  , l.AdjustedEventMonth
	  , case when l.LineItemStatusID = 200 then 1 else 0 end IsCorrectingEntry
  FROM stg.RevenueItemGrouped l
   inner join opt.mea mm on mm.mea = l.MEA 
  LEFT JOIN Enterprisesub.dbo.monetaryUnit m on l.MonetaryUnitID=m.MonetaryUnitID
  LEFT JOIN Enterprisesub.dbo.Costarbrand b on b.CoStarBrandID=l.CoStarBrandID
 LEFT JOIN lookups.GenProdPostingGroup  dpd  on dpd.ProductID = l.DerivedProductID
  LEFT JOIN lookups.CarveInRevenue   crd on crd.ProductID=l.DerivedProductID
  LEFT JOIN lookups.RevenueACCTGSEG1 rad on rad.ProductID=l.DerivedProductID
  where l.MEA is not null --and co.BillingMonth =l.BillingMonth
       and len(l.CurrentSKU)>0   AND l.LineItemStatusID in (1,2,3, 200)  -- 200 indicates a correcting entry
	    AND l.RevenueItemType='SalesOrder'  
		and l.RevenueRunID = @pRevenueRunID
	

	
 --Setting Billing start date to the minimum in the contract

IF (OBJECT_ID('Tempdb..#BillingDate')>0)
   DROP TABLE #BillingDate

SELECT MEA,ContractID,SiteLocationID,Max(BillingStartDate)BillingStartDate
INTO #BillingDate
FROM [stg].RevenueItemRaw
	where RevenueRunID = @pRevenueRunID
GROUP BY ContractID,SiteLocationID,MEA

UPDATE d
SET SCHEDULE_SHIP_DATE=b.BillingStartDate,
    SHIP_DATE         =b.BillingStartDate   
FROM [opt].[RevenueItemProcessed] d
INNER JOIN #BillingDate b ON b.ContractID=d.SALES_ORDER AND d.CUSTOMER_ID=b.SiteLocationID AND d.DEAL_ID=b.MEA
 where RevenueRunID = @pRevenueRunID and  tran_type = 'SO'

 UPDATE h
 SET --[EXT_LIST_PRICE]=[QUANTITY_ORDERED]*[UNIT_LIST_PRICE],
     --[EXT_SELL_PRICE]=[QUANTITY_ORDERED]*[UNIT_SELL_PRICE],
	 RULE_END_DATE    =REPLACE(CONVERT(varchar(11),CAST(RULE_END_DATE as DATE),106), ' ', '-'),
	 RULE_START_DATE  =REPLACE(CONVERT(varchar(11),CAST(RULE_START_DATE as DATE),106), ' ', '-'),
	 SCHEDULE_SHIP_DATE=REPLACE(CONVERT(varchar(11),CAST(SCHEDULE_SHIP_DATE as Date),106), ' ', '-'),
	 SHIP_DATE         =REPLACE(CONVERT(varchar(11),CAST(SHIP_DATE as DATE),106), ' ', '-'), 
     SO_BOOK_DATE      =REPLACE(CONVERT(varchar(11),CAST(SO_BOOK_DATE as DATE),106), ' ', '-'),
	 TRANS_DATE        =REPLACE(CONVERT(varchar(11),CAST(TRANS_DATE as DATE),106), ' ', '-') ,
	 DISCOUNT_AMOUNT   =([UNIT_LIST_PRICE]- [UNIT_SELL_PRICE]),
	 DISCOUNT_PERCENT  =([UNIT_LIST_PRICE]- [UNIT_SELL_PRICE])/[UNIT_LIST_PRICE] 
 FROM [opt].[RevenueItemProcessed] h
 WHERE [UNIT_LIST_PRICE] >0 and  RevenueRunID = @pRevenueRunID and  tran_type = 'SO'



 UPDATE [opt].[RevenueItemProcessed]  SET BUSINESS_UNIT='APTS' WHERE ORG_ID=210
	and  RevenueRunID = @pRevenueRunID and  tran_type = 'SO'

 Update h
set CONVERSION_DATA=CASE WHEN FV_YEAR <2016 THEN 'CONVERSION' ELSE '' END
FROM [opt].[RevenueItemProcessed] h where  RevenueRunID = @pRevenueRunID and  tran_type = 'SO'

  
--update s
--set  EXt_list_Price=EXt_list_Price+ISNULL([STUB_AMOUNT_LISTPRICE],0),
--	 Ext_Sell_Price=Ext_Sell_Price+ISNULL(STUB_AMOUNT,0)
--FROM [opt].[RevenueItemProcessed]  s
--	where  RevenueRunID = @pRevenueRunID

  --UPDATE d
  --SET  SALES_REP_ID =l.[AEContactID]   ,
  --     SALESREP_NAME=l.[AEContactName]
  --FROM  [opt].[RevenueItemProcessed] d
  --INNER JOIN (
  --     select ContractID,[AEContactID],[AEContactName] ,Row_number() over(partition by ContractID order by AEContactID ) as rn 
  --     From stg.RevenueItemRaw
  --     Where AEContactID is not null) l on l.ContractID=d.SALES_ORDER
  --Where l.rn=1 and  RevenueRunID = @pRevenueRunID and  tran_type = 'SO'
 

 --Setting Carv values
 UPDATE d
 SET CARVE_IN_DEF_REVENUE_SEG2=left(rtrim(su.SalesUnitCD),4),
     UNBILLED_AR_SEG2          =left(rtrim(su.SalesUnitCD),4),
	 CARVE_IN_REVENUE_SEG2     =left(rtrim(su.SalesUnitCD),20) ,
     CARVE_OUT_REVENUE_SEG2	   =left(rtrim(su.SalesUnitCD),20),
     ATTRIBUTE25               =left(rtrim(su.SalesUnitCD),20),
     DEF_ACCTG_SEG2            =left(rtrim(su.SalesUnitCD),20),
     REV_ACCTG_SEG2            =left(rtrim(su.SalesUnitCD),20) ,
     LT_DEFERRED_ACCOUNT_SEG5 ='0'
 FROM [opt].[RevenueItemProcessed] d
  INNER JOIN EnterpriseSub.dbo.SalesUnit su on d.DerivedSalesUnitID=su.SalesUnitID
 WHERE su.ProductID in ( 1,2,5)  and  d.RevenueRunID = @pRevenueRunID and  tran_type = 'SO'



  UPDATE d
 SET CARVE_IN_DEF_REVENUE_SEG2= 'USA',-- ISNULL(su.SalesUnitCD,0),
     UNBILLED_AR_SEG2          ='USA',-- ISNULL(su.SalesUnitCD,0)
	 CARVE_IN_REVENUE_SEG2     ='USA',-- ISNULL(su.SalesUnitCD,0),
     CARVE_OUT_REVENUE_SEG2	   ='USA',-- ISNULL(su.SalesUnitCD,0),
     ATTRIBUTE25               ='USA',-- ISNULL(su.SalesUnitCD,0),
     DEF_ACCTG_SEG2            ='USA',-- ISNULL(su.SalesUnitCD,0),
     REV_ACCTG_SEG2            ='USA'-- ISNULL(su.SalesUnitCD,0),
     
 FROM [opt].[RevenueItemProcessed] d
 WHERE d.CoStarBrandID IN (210,2,10) and  d.RevenueRunID = @pRevenueRunID and  tran_type = 'SO'

 --select * from [opt].[RevenueItemProcessed] where SALES_ORDER=153349


RETURN 0

GO
