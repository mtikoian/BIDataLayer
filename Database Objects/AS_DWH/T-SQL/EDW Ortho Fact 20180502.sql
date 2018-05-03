-- EDW Ortho Fact

Truncate TABLE as_stage.dbo.stg_Recast_Fact_SALES_ORDER;

Insert Into as_stage.dbo.stg_Recast_Fact_SALES_ORDER

SELECT    Fact_SALES_ORDER_KEY
		, p.Dim_PRODUCT_KEY
		, ic.Dim_CONMED_ITEM_CATEGORY_KEY
		, stcl.Dim_CUSTOMER_LOCATION_KEY
		, g.Dim_SALES_GEOGRAPHY_KEY
      ,  Case 
            When ic.DIVISION = 'Arthro Power'			Then left([ARTHRO_POWER_TERR], 20)
            When ic.DIVISION  = 'Sports Medicine'		Then left([SPORTS_MEDICINE_TERR], 20)
            When ic.DIVISION  = 'Endoscopy'				Then left([ENDOSCOPY_TERR], 20)
            When ic.DIVISION  = 'Power'					Then left([POWER_TERR], 20)
            When ic.DIVISION  = 'STB'					Then left([CMIS_TERR], 20)
            
            When ic.DIVISION  = 'Conmed Endoscopic Tech' Then left([CONMED_ENDOSCOPIC_TERR], 20)
            When ic.DIVISION  = 'Conmed Electrosurgery'	Then left([CONMED_ELECTROSURGERY_TERR], 20)
            When ic.DIVISION  = 'Conmed Endosurgery'	Then left([CONMED_ENDOSURGERY_TERR], 20)
            When ic.DIVISION  = 'Conmed Patient Care'	Then left([CONMED_PATIENT_CARE_TERR], 20)
            
            When ic.DIVISION  = 'Endoscopic Technologies' Then left([CONMED_ENDOSCOPIC_TERR], 20)
            When ic.MAJOR_DESCRIPTION  = 'Advanced Energy'	Then left([CONMED_ELECTROSURGERY_TERR], 20)
            When ic.MAJOR_DESCRIPTION = 'Endomechanical'	Then left([CONMED_ENDOSURGERY_TERR], 20)
            When ic.DIVISION  = 'Critical Care'			Then left([CONMED_PATIENT_CARE_TERR], 20)
            When ic.DIVISION  = 'Hyfrecator Units & Accessories'		
														Then left([CONMED_ELECTROSURGERY_TERR], 20)
            
            When ic.DIVISION = 'CMIS' Then 'Unknown'
            Else 'Unknown'
            End AS repnum2			
  FROM [AS_DWH].[dbo].[Fact_SALES_ORDER] f
  
  Inner Join [AS_DWH].[dbo].[Dim_product] p
  on f.Dim_PRODUCT_KEY = p.Dim_PRODUCT_KEY
  Inner Join [AS_DWH].[dbo].[Dim_CONMED_ITEM_CATEGORY] ic
  on p.DIM_CONMED_ITEM_CATEGORY_KEY = ic.Dim_CONMED_ITEM_CATEGORY_KEY
    
  Inner Join [AS_DWH].[dbo].Dim_CUSTOMER_LOCATION STCL
  on STCL.Dim_CUSTOMER_LOCATION_KEY = f.Dim_SHIP_TO_CUSTOMER_LOCATION_KEY
  
  Inner Join as_dwh.dbo.Dim_SALES_GEOGRAPHY g
  on g.Dim_SALES_GEOGRAPHY_KEY = f.Dim_SALES_GEOGRAPHY_KEY
  
  Inner Join [AS_DWH].[dbo].Dim_CUSTOMER STC
  on STC.Dim_CUSTOMER_KEY = f.Dim_SHIP_TO_CUSTOMER_KEY
    
  Inner Join [AS_DWH].[dbo].TimeMaster t
  on t.DayID = f.Dim_COMM_SALES_KEY
    
  --Where Dim_COMM_SALES_KEY >= 5115  -- GE Jan 1 2014
  Where t.ActualDate >= '2014-01-01'
  
  and f.Dim_ORDER_SOURCE_SYSTEM_KEY Not In (9, 10)

 -- and stc.ACCOUNT_NUMBER Not IN
	--(SELECT oracle_cust_num
 --    FROM [DW_MAIN].[dbo].[DIST_CUST_ACCOUNTS_TBL])
   
   
Truncate Table as_STAGE.[dbo].[STG_EDW_Fact_SALES_ORDER]

Insert Into as_STAGE.[dbo].[STG_EDW_Fact_SALES_ORDER]

Select [Dim_ORDERED_DATE_KEY], 
		[Dim_INVOICE_DATE_KEY], 
		[Dim_COMM_SALES_KEY], 
		[Dim_OPERATING_UNIT_KEY], 
		[Dim_ORDER_HEADER_TYPE_KEY], 
		[Dim_ORDER_LINE_TYPE_KEY], 
		[Dim_SHIP_TO_CUSTOMER_LOCATION_KEY], 
		[Dim_INVOICE_TO_CUSTOMER_LOCATION_KEY], 
		[Dim_SHIP_TO_CUSTOMER_KEY], 
		f.[Dim_PRODUCT_KEY], 
		s.[Dim_SALES_GEOGRAPHY_KEY], 
		[Dim_ORDER_SOURCE_SYSTEM_KEY], 
		[Dim_GL_COMPANY_SEGMENT_KEY] ,
        [Dim_GL_PRODUCT_SEGMENT_KEY] ,
        Case
			--When [Dim_ORDER_SOURCE_SYSTEM_KEY] = 1 Then 1
			--When [Dim_ORDER_SOURCE_SYSTEM_KEY] = 2 Then 2
			When OHT.TRANSACTION_TYPE_NAME like 'INDIRECT%' Then 2
			Else 1
		End Dim_Direct_Trace_KEY,
		Cast(Cast([ORDER_NUMBER]as Int) As Varchar(150)) [ORDER_NUMBER], 
		[ORACLE_ORDER_LINE_ID], 
		[LINE_NUMBER], 
		[CONTRACT_NUMBER], 
		[ORACLE_CUSTOMER_TRX_LINE_ID], 
		[CUST_PO_NUMBER], 
		[INVOICE_NUMBER], 
		[INVOICE_LINE_ID], 
		[ORDER_REVISION], 
		[FLOW_STATUS_CODE], 
		[FUNCTIONAL_CURRENCY_CODE], 
		[TRANSACTIONAL_CURRENCY_CODE], 
		[ORDERED_QUANTITY], 
		[SHIPPED_QUANTITY], 
		[INVOICED_QUANTITY], 
		[LINE_SELLING_AMOUNT_USD], 
		[LINE_SELLING_AMOUNT_LOCAL], 
		[UNIT_LIST_PRICE_USD], 
		[UNIT_LIST_PRICE_LOCAL], 
		[UNIT_SELLING_PRICE_USD], 
		[UNIT_SELLING_PRICE_LOCAL] [UNIT_SELLING_PRICE_FUNCTIONAL], 
		[UNIT_SELLING_PRICE_TRANSACTIONAL], 
		[INVOICE_SELLING_AMOUNT_USD], 
		[INVOICE_SELLING_AMOUNT_LOCAL] [INVOICE_SELLING_AMOUNT_FUNCTIONAL], 
		[INVOICE_SELLING_AMOUNT_TRANSACTIONAL], 
		[COMM_SELLING_AMOUNT_USD], 
		[COMM_SELLING_AMOUNT_LOCAL] [COMM_SELLING_AMOUNT_FUNCTIONAL], 
		[COMM_SELLING_AMOUNT_TRANSACTIONAL]
		, 0 [INVOICE_SELLING_AMOUNT_CC]
      , 0 [COMM_SELLING_AMOUNT_CC]
      , 0 [Dim_Transaction_Currency_Key]
      , 0 [Dim_Functional_Currency_Key]
      , 0 Dim_GL_Company_Hierarchy_Key
      , Case
			When OHT.TRANSACTION_TYPE_NAME like 'INDIRECT%' Then 5
			When Dim_ORDER_SOURCE_SYSTEM_KEY = 2 Then 7
			Else 1
		End Dim_EXCLUSION_REASON_KEY
	  , f.[Dim_SALES_GEOGRAPHY_KEY] Dim_BSC_GEOGRAPHY_KEY
	  , f.Dim_PRICE_LIST_KEY
	  , 0 Dim_DISTRIBUTPR_KEY
	  , 0 FINANCIAL_SELLING_AMOUNT_USD
	  , 0 FINANCIAL_SELLING_AMOUNT_FUNCTIONAL
	  , 0 FINANCIAL_SELLING_AMOUNT_TRANSACTIONAL
	  , 0 FINANCIAL_SELLING_AMOUNT_CC
	  , F.Dim_Sales_GL_ACCOUNT_KEY
	  , F.Dim_Revenue_GL_ACCOUNT_KEY
	  , 0 Dim_TRX_GL_ACCOUNT_KEY 
	 , Case
			When OHT.TRANSACTION_TYPE_NAME like 'INDIRECT%' Then
				[Dim_ORDERED_DATE_KEY]
	  		ELSE [Dim_INVOICE_DATE_KEY] 
	   END Dim_GL_DATE_KEY
	  , Unit_Cost_Local	            Product_Cost_Functional
	  , Unit_Cost_USD               Product_Cost_USD
	  , Invoice_Cost_Amount_Local   Product_Cost_Extended_Functional
	  , Invoice_Cost_Amount_USD     Product_Cost_Extended_USD
	  , Invoice_Profit_Margin_LOCAL Invoice_Margin_Functional
	  , Invoice_Profit_Margin_USD   Invoice_Margin_USD
	  , 0							Dim_Cost_GL_ACCOUNT_KEY
	  , 0							REBATE_AMOUNT_USD
	  , 0							Submission_Line_Number
	  , Case 
			-- Corporate ASP
			-- Exclude $0 Orders
			When OHT.TRANSACTION_TYPE_NAME like 'INDIRECT%' 
			 Or  [INVOICE_SELLING_AMOUNT_USD] = 0 Then 0
			-- Inclusions 
			When OHT.TRANSACTION_TYPE_NAME like 'DELIVERED%' And 
			 (OLT.TRANSACTION_TYPE_NAME like 'CREDIT%'
			  Or OLT.TRANSACTION_TYPE_NAME like 'DELIVERED%') Then INVOICED_QUANTITY
			When OHT.TRANSACTION_TYPE_NAME like 'GIVE AWAY%' And 
			 (OLT.TRANSACTION_TYPE_NAME like 'RETURN WITH RECEIPT%'
			  Or OLT.TRANSACTION_TYPE_NAME like 'BILL ONLY%'
			  Or OLT.TRANSACTION_TYPE_NAME like 'STANDARD%') Then INVOICED_QUANTITY
			When OHT.TRANSACTION_TYPE_NAME like 'REPLACEMENT IT%' And 
			 (OLT.TRANSACTION_TYPE_NAME like 'RETURN WITH RECEIPT%'
			  Or OLT.TRANSACTION_TYPE_NAME like 'BILL ONLY%'
			  Or OLT.TRANSACTION_TYPE_NAME like 'STANDARD%') Then INVOICED_QUANTITY
			When OHT.TRANSACTION_TYPE_NAME like 'SALES%SAMPLE%' And 
			 (OLT.TRANSACTION_TYPE_NAME like 'RETURN WITH RECEIPT%'
			  Or OLT.TRANSACTION_TYPE_NAME like 'BILL ONLY%'
			  Or OLT.TRANSACTION_TYPE_NAME like 'STANDARD%') Then INVOICED_QUANTITY
			When OHT.TRANSACTION_TYPE_NAME like 'SERVICE REPAIR%' And 
			 (OLT.TRANSACTION_TYPE_NAME like '%SERVICE RMA%'
			  Or OLT.TRANSACTION_TYPE_NAME like 'BILL ONLY%'
			  Or OLT.TRANSACTION_TYPE_NAME like 'SERVICE SHIP%') Then INVOICED_QUANTITY
			When (OHT.TRANSACTION_TYPE_NAME like 'STANDARD%' Or 
				OHT.TRANSACTION_TYPE_NAME like 'FINANCE USE ONLY%') And
			 (OLT.TRANSACTION_TYPE_NAME like 'BILL ONLY%') Then INVOICED_QUANTITY
			 
			-- Exclusions 
			When OHT.TRANSACTION_TYPE_NAME like 'CREDIT%' Or 
				 OHT.TRANSACTION_TYPE_NAME like 'ADVANTAGE%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'HOUSE EVAL%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'AFFILIATE%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'REBATE%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'CONTRACT%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'INTERNAL - AU%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'SERVICE PROGRAMS%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'RENTALS - IT%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'CONMED%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'EUROPE LOANER %' Or
				 OHT.TRANSACTION_TYPE_NAME like 'Undefined%'  Then 0
			When OLT.TRANSACTION_TYPE_NAME like '%SERVICE AFFL%SHIP%' Or
				  OLT.TRANSACTION_TYPE_NAME like 'CREDIT%' Or
				  OLT.TRANSACTION_TYPE_NAME like 'CMIS CREDIT ONLY - CA' Or
				  OLT.TRANSACTION_TYPE_NAME like 'CMIS BILLING - CA' Or
				  OLT.TRANSACTION_TYPE_NAME Like 'Undefined%' Then 0
			When OHT.TRANSACTION_TYPE_NAME like 'SERVICE REPAIR%' And 
			 	  OLT.TRANSACTION_TYPE_NAME like 'SERVICE CREDIT ONLY%' Then 0
			When OHT.TRANSACTION_TYPE_NAME like 'USED PRODUCT%' And 
			 	  OLT.TRANSACTION_TYPE_NAME like 'USED CREDIT ONLY%' Then 0
			When OHT.TRANSACTION_TYPE_NAME like 'REPAIR - IT%' And
				 OLT.TRANSACTION_TYPE_NAME like 'BILL ONLY%' Then 0
			When OLT.TRANSACTION_TYPE_NAME like 'SERVICE AFFL%' Then 0
			Else INVOICED_QUANTITY
	    End Corporate_ASP_Quantity 
	   
	    -- Repair Quantity
		, Case 
			-- RtnRepair
			When OLT.TRANSACTION_TYPE_NAME like '%SERVICE AFFL%SHIP%' 
				Or OLT.TRANSACTION_TYPE_NAME like '%SERVICE SHIP%' Then INVOICED_QUANTITY
			Else 0
	    End Repair_Quantity 
	    
	    -- Other ASP
	    , Case 
			When OHT.TRANSACTION_TYPE_NAME like 'CREDIT%' Or 
				 OHT.TRANSACTION_TYPE_NAME like 'ADVANTAGE%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'HOUSE EVAL%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'AFFILIATE%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'REBATE%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'CONTRACT%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'INTERNAL - AU%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'SERVICE PROGRAMS%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'RENTALS - IT%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'CONMED%' Or 
				 OHT.TRANSACTION_TYPE_NAME like 'EUROPE LOANER %' Or
				 OHT.TRANSACTION_TYPE_NAME like 'INDIRECT%' Or
				 OHT.TRANSACTION_TYPE_NAME like 'Undefined%' Then 0
			-- RtnRepair
			When OLT.TRANSACTION_TYPE_NAME like '%SERVICE AFFL%%' 
				Or OLT.TRANSACTION_TYPE_NAME like '%SERVICE SHIP%' 
				Or OLT.TRANSACTION_TYPE_NAME like 'Undefined%' Then 0
			Else INVOICED_QUANTITY
	    End Other_ASP_Quantity
	  , INVOICE_COST_AMOUNT_LESS_MARKUP_LOCAL
									Product_Cost_Less_MarkUp_Extended_Functional
	  , INVOICE_COST_AMOUNT_LESS_MARKUP_usd
									Product_Cost_Less_MarkUp_Extended_USD
	  , Invoice_Cost_Amount_USD     Comm_Product_Cost_Extended_USD
	  , Invoice_Profit_Margin_USD	Comm_Margin_USD
	  , Null						mnlAdjID

From as_dwh.dbo.fact_sales_order f

Inner join as_stage.dbo.stg_Recast_Fact_SALES_ORDER s
on f.Fact_SALES_ORDER_KEY = s.Fact_SALES_ORDER_KEY

inner join as_dwh.dbo.Dim_SHIP_TO_CUSTOMER_LOCATION_V cl
on f.Dim_SHIP_TO_CUSTOMER_LOCATION_KEY = cl.Dim_CUSTOMER_LOCATION_KEY
  
Inner Join [AS_DWH].[dbo].Dim_CUSTOMER STC
on STC.Dim_CUSTOMER_KEY = f.Dim_SHIP_TO_CUSTOMER_KEY

Inner Join [AS_DWH].[dbo].Dim_ORDER_TYPE OHT
  on oht.Dim_ORDER_TYPE_KEY = f.Dim_ORDER_HEADER_TYPE_KEY
 
Inner Join [AS_DWH].[dbo].Dim_ORDER_TYPE OLT
  on olt.Dim_ORDER_TYPE_KEY = f.Dim_ORDER_LINE_TYPE_KEY



-- Set Dealer Exclusion Reason
Update as_STAGE.[dbo].[STG_EDW_Fact_SALES_ORDER]
	Set Dim_EXCLUSION_REASON_KEY = 4
		, [COMM_SELLING_AMOUNT_USD] = 0 
		, [COMM_SELLING_AMOUNT_FUNCTIONAL] = 0 
		, [COMM_SELLING_AMOUNT_TRANSACTIONAL] = 0
		, [COMM_SELLING_AMOUNT_CC] = 0
		, Comm_Product_Cost_Extended_USD = 0
	    , Comm_Margin_USD = 0
FROM as_STAGE.[dbo].[STG_EDW_Fact_SALES_ORDER] f
Inner Join [AS_DWH].[dbo].Dim_CUSTOMER STC
on stc.Dim_CUSTOMER_KEY = f.Dim_SHIP_TO_CUSTOMER_KEY
	
Where stc.ACCOUNT_NUMBER IN
	(SELECT oracle_cust_num
     FROM [DW_MAIN].[dbo].[DIST_CUST_ACCOUNTS_TBL])


-- Italy Sales Rep Override. IF Order Type is Repair IT use territory zz1
Update as_STAGE.[dbo].[STG_EDW_Fact_SALES_ORDER]
	Set Dim_SALES_GEOGRAPHY_KEY = Coalesce(g.Dim_SALES_GEOGRAPHY_KEY, 0)
FROM as_STAGE.[dbo].[STG_EDW_Fact_SALES_ORDER] f
Inner Join [AS_DWH].[dbo].Dim_ORDER_TYPE OHT
  on oht.Dim_ORDER_TYPE_KEY = f.Dim_ORDER_HEADER_TYPE_KEY
Left Join as_Dwh.dbo.Dim_SALES_GEOGRAPHY g
on 'ZZ1' = g.GEOGID
Where OHT.TRANSACTION_TYPE_NAME like 'REPAIR - IT%' 
