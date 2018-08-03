USE [RevPro]
GO
/****** Object:  Table [dbo].[Credit_Memo_Archive]    Script Date: 1/29/2018 3:17:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Credit_Memo_Archive](
	[Archive_ID] [int] IDENTITY(1,1) NOT NULL,
	[DW_STG_ID] [int] NOT NULL,
	[CLIENT_ID] [varchar](100) NULL,
	[Deal_ID_CurrentTermStartDate] [datetime] NULL,
	[Deal_ID_CreatedDate] [datetime] NULL,
	[Deal_ID_LocationID] [varchar](100) NULL,
	[CARVE_IN_DEF_REVENUE_SEG1] [varchar](100) NULL,
	[CARVE_IN_DEF_REVENUE_SEG2] [varchar](100) NULL,
	[CARVE_IN_DEF_REVENUE_SEG3] [varchar](100) NULL,
	[CARVE_IN_DEF_REVENUE_SEG4] [varchar](100) NULL,
	[UNBILLED_AR_SEG1] [varchar](100) NULL,
	[UNBILLED_AR_SEG2] [varchar](100) NULL,
	[UNBILLED_AR_SEG3] [varchar](100) NULL,
	[UNBILLED_AR_SEG4] [varchar](100) NULL,
	[CARVE_IN_REVENUE_SEG1] [varchar](100) NULL,
	[CARVE_IN_REVENUE_SEG2] [varchar](100) NULL,
	[CARVE_IN_REVENUE_SEG3] [varchar](100) NULL,
	[CARVE_IN_REVENUE_SEG4] [varchar](100) NULL,
	[CARVE_OUT_REVENUE_SEG1] [varchar](100) NULL,
	[CARVE_OUT_REVENUE_SEG2] [varchar](100) NULL,
	[CARVE_OUT_REVENUE_SEG3] [varchar](100) NULL,
	[CARVE_OUT_REVENUE_SEG4] [varchar](100) NULL,
	[ATTRIBUTE24] [bit] NOT NULL,
	[ATTRIBUTE25] [varchar](100) NULL,
	[ATTRIBUTE26] [varchar](100) NOT NULL,
	[ATTRIBUTE27] [varchar](100) NULL,
	[BASE_CURR_CODE] [varchar](100) NULL,
	[BILL_TO_COUNTRY] [varchar](100) NULL,
	[BILL_TO_CUSTOMER_NAME] [varchar](100) NULL,
	[BILL_TO_CUSTOMER_NUMBER] [int] NOT NULL,
	[BUSINESS_UNIT] [varchar](100) NULL,
	[CUSTOMER_ID] [int] NOT NULL,
	[CUSTOMER_NAME] [varchar](100) NULL,
	[DEF_ACCTG_SEG1] [varchar](100) NULL,
	[DEF_ACCTG_SEG2] [varchar](100) NULL,
	[DEF_ACCTG_SEG3] [varchar](100) NULL,
	[DEF_ACCTG_SEG4] [varchar](100) NULL,
	[DEFERRED_REVENUE_FLAG] [varchar](1) NOT NULL,
	[DISCOUNT_AMOUNT] [numeric](38, 20) NULL,
	[DISCOUNT_PERCENT] [varchar](100) NOT NULL,
	[ELIGIBLE_FOR_CV_CreateDated] [smalldatetime] NOT NULL,
	[ELIGIBLE_FOR_FV_CreateDated] [smalldatetime] NOT NULL,
	[EX_RATE] [numeric](2, 1) NULL,
	[EXT_LIST_PRICE] [numeric](18, 2) NULL,
	[EXT_SELL_PRICE] [numeric](18, 2) NULL,
	[FLAG_97_2] [varchar](1) NOT NULL,
	[INVOICE_DATE] [datetime] NULL,
	[INVOICE_ID] [varchar](100) NOT NULL,
	[INVOICE_LINE] [varchar](100) NOT NULL,
	[INVOICE_LINE_ID] [varchar](100) NULL,
	[INVOICE_NUMBER] [varchar](100) NULL,
	[INVOICE_TYPE] [varchar](100) NOT NULL,
	[ITEM_DESC] [varchar](100) NOT NULL,
	[ITEM_ID] [int] NOT NULL,
	[ITEM_NUMBER] [varchar](100) NOT NULL,
	[LT_DEFERRED_ACCOUNT] [varchar](100) NOT NULL,
	[NON_CONTINGENT_FLAG] [varchar](1) NOT NULL,
	[ORDER_LINE_TYPE] [varchar](100) NOT NULL,
	[ORDER_TYPE] [varchar](100) NOT NULL,
	[ORG_ID] [tinyint] NULL,
	[ORIG_INV_LINE_ID] [varchar](100) NOT NULL,
	[PCS_FLAG] [varchar](1) NOT NULL,
	[PO_NUM] [varchar](100) NOT NULL,
	[PRODUCT_CATEGORY] [int] NOT NULL,
	[PRODUCT_CLASS] [int] NULL,
	[PRODUCT_FAMILY] [varchar](100) NULL,
	[PRODUCT_LINE] [varchar](100) NOT NULL,
	[QUANTITY_INVOICED] [varchar](100) NOT NULL,
	[QUANTITY_ORDERED_SHIPPED_BillingStartDate] [smalldatetime] NULL,
	[QUANTITY_ORDERED_SHIPPED_RenewalDate] [smalldatetime] NULL,
	[QUOTE_NUM] [varchar](100) NOT NULL,
	[RCURR_EX_RATE] [numeric](2, 1) NULL,
	[RETURN_FLAG] [varchar](1) NOT NULL,
	[REV_ACCTG_SEG1] [varchar](100) NULL,
	[REV_ACCTG_SEG2] [varchar](100) NULL,
	[REV_ACCTG_SEG3] [varchar](100) NULL,
	[REV_ACCTG_SEG4] [varchar](100) NULL,
	[RULE_END_DATE] [datetime] NULL,
	[RULE_START_DATE] [datetime] NULL,
	[SALES_ORDER] [int] NOT NULL,
	[SALES_ORDER_ID] [int] NOT NULL,
	[SALES_ORDER_LINE] [int] NOT NULL,
	[SALES_ORDER_LINE_ID] [varchar](100) NULL,
	[SALES_REP_ID] [int] NULL,
	[SALESREP_NAME] [varchar](100) NULL,
	[SCHEDULE_SHIP_DATE] [datetime] NULL,
	[SEC_ATTR_VALUE] [varchar](100) NOT NULL,
	[SHIP_DATE] [datetime] NULL,
	[SO_BOOK_DATE] [datetime] NULL,
	[SOB_ID] [varchar](100) NOT NULL,
	[STANDALONE_FLAG] [varchar](1) NOT NULL,
	[STATED_FLAG] [varchar](1) NOT NULL,
	[TRAN_TYPE] [varchar](100) NOT NULL,
	[TRANS_CURR_CODE] [varchar](100) NULL,
	[TRANS_DATE] [datetime] NULL,
	[UNBILLED_ACCOUNTING_FLAG] [varchar](1) NOT NULL,
	[UNDELIVERED_FLAG] [varchar](1) NOT NULL,
	[UNIT_LIST_PRICE] [numeric](18, 2) NULL,
	[UNIT_SELL_PRICE] [numeric](18, 2) NULL,
	[FV_YEAR] [int] NULL,
	[STUB_AMOUNT] [varchar](100) NOT NULL,
	[CONVERSION_DATA_CreatedDate] [smalldatetime] NOT NULL,
	[CANCELLED_FLAG_LineItemStatusID] [tinyint] NOT NULL,
	[CARVE_IN_DEF_REVENUE_SEG5] [varchar](100) NOT NULL,
	[UNBILLED_AR_SEG5] [varchar](100) NOT NULL,
	[CARVE_IN_REVENUE_SEG5] [varchar](100) NOT NULL,
	[CARVE_OUT_REVENUE_SEG5] [varchar](100) NOT NULL,
	[DEF_ACCTG_SEG5] [varchar](100) NOT NULL,
	[REV_ACCTG_SEG5] [varchar](100) NOT NULL,
	[LT_DEFERRED_ACCOUNT_SEG5] [varchar](100) NOT NULL,
	[ATTRIBUTE28] [varchar](100) NOT NULL,
	[NUMBER5] [varchar](100) NOT NULL,
	[Attribute1] [varchar](100) NOT NULL,
	[Attribute2] [varchar](100) NOT NULL,
	[Attribute3] [varchar](100) NOT NULL,
	[Attribute4] [varchar](100) NOT NULL,
	[Attribute5] [varchar](100) NOT NULL,
	[Attribute6] [varchar](100) NOT NULL,
	[Attribute7] [varchar](100) NOT NULL,
	[Attribute8] [varchar](100) NOT NULL,
	[Attribute9] [varchar](100) NOT NULL,
	[Attribute10] [varchar](100) NOT NULL,
	[BundleID] [int] NULL,
	[BatchID] [int] NULL,
	[DW_Fl] [varchar](1) NOT NULL,
	[RPro_Fl] [varchar](2) NOT NULL,
	[Created_By] [varchar](100) NOT NULL,
	[Create_Dt] [datetime] NOT NULL,
	[Last_Updated_By] [varchar](100) NOT NULL,
	[Last_Update_Dt] [datetime] NOT NULL,
	[CheckSum_Credit_Memo_Archive]  AS (checksum([CLIENT_ID],[Deal_ID_CurrentTermStartDate],[Deal_ID_CreatedDate],[Deal_ID_LocationID],[CARVE_IN_DEF_REVENUE_SEG1],[CARVE_IN_DEF_REVENUE_SEG2],[CARVE_IN_DEF_REVENUE_SEG3],[CARVE_IN_DEF_REVENUE_SEG4],[UNBILLED_AR_SEG1],[UNBILLED_AR_SEG2],[UNBILLED_AR_SEG3],[UNBILLED_AR_SEG4],[CARVE_IN_REVENUE_SEG1],[CARVE_IN_REVENUE_SEG2],[CARVE_IN_REVENUE_SEG3],[CARVE_IN_REVENUE_SEG4],[CARVE_OUT_REVENUE_SEG1],[CARVE_OUT_REVENUE_SEG2],[CARVE_OUT_REVENUE_SEG3],[CARVE_OUT_REVENUE_SEG4],[ATTRIBUTE24],[ATTRIBUTE25],[ATTRIBUTE26],[ATTRIBUTE27],[BASE_CURR_CODE],[BILL_TO_COUNTRY],[BILL_TO_CUSTOMER_NAME],[BILL_TO_CUSTOMER_NUMBER],[BUSINESS_UNIT],[CUSTOMER_ID],[CUSTOMER_NAME],[DEF_ACCTG_SEG1],[DEF_ACCTG_SEG2],[DEF_ACCTG_SEG3],[DEF_ACCTG_SEG4],[DEFERRED_REVENUE_FLAG],[DISCOUNT_AMOUNT],[DISCOUNT_PERCENT],[ELIGIBLE_FOR_CV_CreateDated],[ELIGIBLE_FOR_FV_CreateDated],[EX_RATE],[EXT_LIST_PRICE],[EXT_SELL_PRICE],[FLAG_97_2],[INVOICE_DATE],[INVOICE_ID],[INVOICE_LINE],[INVOICE_LINE_ID],[INVOICE_NUMBER],[INVOICE_TYPE],[ITEM_DESC],[ITEM_ID],[ITEM_NUMBER],[LT_DEFERRED_ACCOUNT],[NON_CONTINGENT_FLAG],[ORDER_LINE_TYPE],[ORDER_TYPE],[ORG_ID],[ORIG_INV_LINE_ID],[PCS_FLAG],[PO_NUM],[PRODUCT_CATEGORY],[PRODUCT_CLASS],[PRODUCT_FAMILY],[PRODUCT_LINE],[QUANTITY_INVOICED],[QUANTITY_ORDERED_SHIPPED_BillingStartDate],[QUANTITY_ORDERED_SHIPPED_RenewalDate],[QUOTE_NUM],[RCURR_EX_RATE],[RETURN_FLAG],[REV_ACCTG_SEG1],[REV_ACCTG_SEG2],[REV_ACCTG_SEG3],[REV_ACCTG_SEG4],[RULE_END_DATE],[RULE_START_DATE],[SALES_ORDER],[SALES_ORDER_ID],[SALES_ORDER_LINE],[SALES_ORDER_LINE_ID],[SALES_REP_ID],[SALESREP_NAME],[SCHEDULE_SHIP_DATE],[SEC_ATTR_VALUE],[SHIP_DATE],[SO_BOOK_DATE],[SOB_ID],[STANDALONE_FLAG],[STATED_FLAG],[TRAN_TYPE],[TRANS_CURR_CODE],[TRANS_DATE],[UNBILLED_ACCOUNTING_FLAG],[UNDELIVERED_FLAG],[UNIT_LIST_PRICE],[UNIT_SELL_PRICE],[FV_YEAR],[STUB_AMOUNT],[CONVERSION_DATA_CreatedDate],[CANCELLED_FLAG_LineItemStatusID],[CARVE_IN_DEF_REVENUE_SEG5],[UNBILLED_AR_SEG5],[CARVE_IN_REVENUE_SEG5],[CARVE_OUT_REVENUE_SEG5],[DEF_ACCTG_SEG5],[REV_ACCTG_SEG5],[LT_DEFERRED_ACCOUNT_SEG5],[ATTRIBUTE28],[NUMBER5])),
 CONSTRAINT [PK_Credit_Memo_Archive_Archive_ID] PRIMARY KEY CLUSTERED 
(
	[Archive_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
