
-- Manman Journals
  Insert Into as_STAGE.[dbo].[STG_EDW_Fact_SALES_ORDER]
  ([Dim_ORDERED_DATE_KEY]  ,[Dim_INVOICE_DATE_KEY] ,[Dim_COMM_SALES_KEY] ,[Dim_OPERATING_UNIT_KEY]
 ,[Dim_ORDER_HEADER_TYPE_KEY] ,[Dim_ORDER_LINE_TYPE_KEY] ,[Dim_SHIP_TO_CUSTOMER_LOCATION_KEY]
 ,[Dim_INVOICE_TO_CUSTOMER_LOCATION_KEY]  ,[Dim_SHIP_TO_CUSTOMER_KEY] ,[Dim_PRODUCT_KEY]
 ,[Dim_SALES_GEOGRAPHY_KEY] ,[Dim_ORDER_SOURCE_SYSTEM_KEY] ,[Dim_GL_COMPANY_SEGMENT_KEY]
 ,[Dim_GL_PRODUCT_SEGMENT_KEY] ,[Dim_Direct_Trace_KEY] ,[ORDER_NUMBER] ,[ORACLE_ORDER_LINE_ID]
 ,[LINE_NUMBER] ,[CONTRACT_NUMBER] ,[ORACLE_CUSTOMER_TRX_LINE_ID] ,[CUST_PO_NUMBER] ,[INVOICE_NUMBER]
 ,[INVOICE_LINE_ID] ,[ORDER_REVISION] ,[FLOW_STATUS_CODE] ,[FUNCTIONAL_CURRENCY_CODE] ,[TRANSACTIONAL_CURRENCY_CODE]
 ,[ORDERED_QUANTITY] ,[SHIPPED_QUANTITY] ,[INVOICED_QUANTITY] ,[LINE_SELLING_AMOUNT_USD] ,[LINE_SELLING_AMOUNT_LOCAL]
 ,[UNIT_LIST_PRICE_USD] ,[UNIT_LIST_PRICE_LOCAL] ,[UNIT_SELLING_PRICE_USD] ,[UNIT_SELLING_PRICE_FUNCTIONAL]
 ,[UNIT_SELLING_PRICE_TRANSACTIONAL] ,[INVOICE_SELLING_AMOUNT_USD] ,[INVOICE_SELLING_AMOUNT_FUNCTIONAL]
 ,[INVOICE_SELLING_AMOUNT_TRANSACTIONAL] ,[COMM_SELLING_AMOUNT_USD] ,[COMM_SELLING_AMOUNT_FUNCTIONAL]
 ,[COMM_SELLING_AMOUNT_TRANSACTIONAL] ,[INVOICE_SELLING_AMOUNT_CC] ,[COMM_SELLING_AMOUNT_CC] 
 ,[Dim_Transaction_Currency_Key] ,[Dim_Functional_Currency_Key] ,[Dim_GL_Company_Hierarchy_Key]
 ,[Dim_EXCLUSION_REASON_KEY] ,[Dim_BSC_SALES_GEOGRAPHY_KEY] ,[Dim_PRICE_LIST_KEY] ,[Dim_DISTRIBUTOR_KEY]
 ,[FINANCIAL_SELLING_AMOUNT_USD] ,[FINANCIAL_SELLING_AMOUNT_FUNCTIONAL] ,[FINANCIAL_SELLING_AMOUNT_TRANSACTIONAL]
 ,[FINANCIAL_SELLING_AMOUNT_CC] ,[Dim_Sales_GL_ACCOUNT_KEY] ,[Dim_Revenue_GL_ACCOUNT_KEY] ,[Dim_TRX_GL_ACCOUNT_KEY]
 ,[Dim_GL_DATE_KEY] ,[Product_Cost_Functional] ,[Product_Cost_USD] ,[Product_Cost_Extended_Functional]
 ,[Product_Cost_Extended_USD] ,[Invoice_Margin_Functional] ,[Invoice_Margin_USD] ,[Dim_Cost_GL_ACCOUNT_KEY]
 ,[REBATE_AMOUNT_USD] ,[Submission_Line_Number] ,[Corporate_ASP_Quantity] ,[Repair_Quantity]
 ,[Other_ASP_Quantity] ,[Product_Cost_Less_MarkUp_Extended_Functional] ,[Product_Cost_Less_MarkUp_Extended_USD])
   
  Select Coalesce(Gd.dayid, -1)	[Dim_ORDERED_DATE_KEY], 
		Coalesce(Gd.dayid, -1)	[Dim_INVOICE_DATE_KEY], 
		Coalesce(Gd.dayid, -1)	[Dim_COMM_SALES_KEY], 
		-1						[Dim_OPERATING_UNIT_KEY], 
		-5						[Dim_ORDER_HEADER_TYPE_KEY], 
		-5						[Dim_ORDER_LINE_TYPE_KEY], 
		0						[Dim_SHIP_TO_CUSTOMER_LOCATION_KEY], 
		0						[Dim_INVOICE_TO_CUSTOMER_LOCATION_KEY], 
		0						[Dim_SHIP_TO_CUSTOMER_KEY], 
		0						[Dim_PRODUCT_KEY], 
		0						[Dim_SALES_GEOGRAPHY_KEY], 
		14						Dim_ORDER_SOURCE_SYSTEM_KEY,
		CoCode					[Dim_GL_COMPANY_SEGMENT_KEY],
		coalesce(ProductSegment,'0000')		
								[Dim_GL_PRODUCT_SEGMENT_KEY],
		1						Dim_Direct_Trace_KEY,

		Null					[ORDER_NUMBER], 
		Null					[ORACLE_ORDER_LINE_ID], 
		Null					[LINE_NUMBER], 

		Null					[CONTRACT_NUMBER], 
		0						[ORACLE_CUSTOMER_TRX_LINE_ID], 

		Null					[CUST_PO_NUMBER], 
		Null					[INVOICE_NUMBER], 
		Null					[INVOICE_LINE_ID],			
		Null					[ORDER_REVISION], 			
		'CLOSED'				[FLOW_STATUS_CODE], 

		'USD'					[FUNCTIONAL_CURRENCY_CODE], 
		'USD'					[TRANSACTIONAL_CURRENCY_CODE], 

		0						[ORDERED_QUANTITY],			
		Null					[SHIPPED_QUANTITY],			
		0						[INVOICED_QUANTITY], 

		Null					[LINE_SELLING_AMOUNT_USD], 
		Null					[LINE_SELLING_AMOUNT_LOCAL],
		
		Null					[UNIT_LIST_PRICE_USD], 
		Null					[UNIT_LIST_PRICE_LOCAL], 

		Null					[UNIT_SELLING_PRICE_USD], 
		Null					[UNIT_SELLING_PRICE_FUNCTIONAL],
		f.[GL_PostAmt]			[UNIT_SELLING_PRICE_TRANSACTIONAL],

		0						[INVOICE_SELLING_AMOUNT_USD],
		0						[INVOICE_SELLING_AMOUNT_FUNCTIONAL],
		0						[INVOICE_SELLING_AMOUNT_TRANSACTIONAL], 

		0						[COMM_SELLING_AMOUNT_USD], 
		0						[COMM_SELLING_AMOUNT_FUNCTIONAL], 
		0						[COMM_SELLING_AMOUNT_TRANSACTIONAL],
	    0						[INVOICE_SELLING_AMOUNT_CC]
      , 0						[COMM_SELLING_AMOUNT_CC]
      
      , tcurr.Dim_CURRENCY_KEY
		
      , fcurr.Dim_CURRENCY_KEY
		
      , (SELECT MAX(Dim_GL_COMPANY_Hierarchy_KEY) Dim_GL_COMPANY_KEY
		 FROM [AS_DWH].[EDW].[Dim_GL_COMPANY_Hierarchy]
		 WHERE GL_COMPANY = f.CoCode  
		 GROUP BY GL_COMPANY)		Dim_GL_Company_Hierarchy_Key
		 
      , Case 
			When GL_PostSource Is Null Then -- Prior Year GL Special Input
				 23
			Else 10 End 		Dim_EXCLUSION_REASON_KEY
      , 0						[Dim_BSC_SALES_GEOGRAPHY_KEY]
      , -1						[Dim_PRICE_LIST_KEY]
      , 0						Dim_Distributor_Key
      
      , f.[GL_PostAmt]			[FINANCIAL_SELLING_AMOUNT_USD]
	  ,	f.[GL_PostAmt]			[FINANCIAL_SELLING_AMOUNT_FUNCTIONAL] 
	  ,	f.[GL_PostAmt]			[FINANCIAL_SELLING_AMOUNT_TRANSACTIONAL]
	  , f.[GL_PostAmt]			[FINANCIAL_SELLING_AMOUNT_CC]
	  , Coalesce(ta.Dim_GL_ACCOUNT_KEY,0)	Dim_Sales_GL_ACCOUNT_KEY
	  , Coalesce(ta.Dim_GL_ACCOUNT_KEY,0)	Dim_Revenue_GL_ACCOUNT_KEY
	  , Coalesce(ta.Dim_GL_ACCOUNT_KEY,0)	Dim_TRX_GL_ACCOUNT_KEY
	  , Coalesce(Gd.dayid, -1)	Dim_GL_DATE_KEY
	  , 0 Product_Cost_Functional
	  , 0 Product_Cost_USD
	  , 0 Product_Cost_Extended_Functional
	  , 0 Product_Cost_Extended_USD
	  , 0 Invoice_Margin_Functional
	  , 0 Invoice_Margin_USD
	  , Coalesce(ta.Dim_GL_ACCOUNT_KEY,0)	 Dim_Cost_GL_ACCOUNT_KEY
	  , 0 REBATE_AMOUNT_USD
	  , 0 Submission_Line_Number
	  , 0 Corporate_ATS_Quantity 
	  , 0 Repair_Quantity 
	  , 0 Other_ATS_Quantity
	  , 0 Product_Cost_Less_MarkUp_Extended_Functional
	  , 0 Product_Cost_Less_MarkUp_Extended_USD
		
  From 
	(Select *
	 From As_Stage.dbo.Manman_JournalEntries
	 Union All
	 Select *
	 From AS_STAGE.dbo.LU_Prior_Year_GL_Adjustments_Manman) f

  left join as_dwh.dbo.TimeMaster gd
  on CAST(f.GL_POSTTRDATE AS DATE) = gd.ActualDate

  Left Join as_dwh.dbo.Dim_Currency tcurr
  on tcurr.CURRENCY_CODE = 'USD'
  
  Left Join as_dwh.dbo.Dim_Currency fcurr
  on fcurr.CURRENCY_CODE = 'USD'

  --Left Join AS_DWH.dbo.Dim_GL_ACCOUNT gl
  --on gl.CONCATENATED_SEGMENTS = RTRIM(GL_AcctNo)
  
Left join [AS_DWH].EDW.Dim_GL_ACCOUNT_V ta
on ta.Concatenated_Segments = Coalesce(RTRIM(GL_AcctNo),'Undefined')

  
  --Left join dbo.Dim_GL_ACCOUNT_PRODUCT_V p
  --on f.ProductSegment = p.PRODUCT

