-- Fact_Contract_Sales

Declare @StartDate date

Select @StartDate = YearFirstDate
from as_dwh.dbo.timemaster
Where actualdate = Cast(dateadd(year,-2,Getdate()) as Date)

Truncate Table as_dwh.edw.Fact_Contract_Sales
Insert Into as_dwh.edw.Fact_Contract_Sales
Select f.Dim_SHIP_TO_CUSTOMER_LOCATION_KEY
	, f.Dim_Price_list_Key
	, f.Dim_Product_Key
	, f.Dim_Sales_Geography_Key
	, Coalesce(c.Dim_Contract_Customer_key,0) Dim_Contract_Customer_key
	, Coalesce(r.Dim_Contracts_Reporting_key,0) Dim_Contracts_Reporting_key
	, Coalesce(pp.Dim_Product_Pricelist_key,0) Dim_Product_Pricelist_key 
	, f.[Dim_COMM_SALES_KEY]
	, f.[Dim_GL_DATE_KEY]
	, f.[Dim_OPERATING_UNIT_KEY]
	, f.[Dim_ORDER_HEADER_TYPE_KEY]
	, f.[Dim_ORDER_LINE_TYPE_KEY]
	, f.[Dim_INVOICE_TO_CUSTOMER_LOCATION_KEY]
	, f.[Dim_ORDER_SOURCE_SYSTEM_KEY]
	, f.[Dim_GL_COMPANY_SEGMENT_KEY]
	, f.[Dim_GL_PRODUCT_SEGMENT_KEY]
	, f.Dim_Direct_Trace_KEY
	, f.[ORDER_NUMBER]
	, f.[ORACLE_ORDER_LINE_ID]
	, f.[LINE_NUMBER]
	, f.[CONTRACT_NUMBER]
	, Case 
		When ot.TRANSACTION_TYPE_NAME like 'MTF Transaction%' Then 
			f.COMM_SELLING_AMOUNT_TRANSACTIONAL
		Else UNIT_LIST_PRICE_LOCAL * Corporate_ASP_Quantity
		End			List_Price_Local
	, Case 
		When ot.TRANSACTION_TYPE_NAME like 'MTF Transaction%' Then 
			f.COMM_SELLING_AMOUNT_TRANSACTIONAL
		Else UNIT_SELLING_PRICE_TRANSACTIONAL * Corporate_ASP_Quantity 
		End			Selling_Price_Local
	, Case 
		When ot.TRANSACTION_TYPE_NAME like 'MTF Transaction%' Then 
			f.COMM_SELLING_AMOUNT_USD
		Else UNIT_LIST_PRICE_USD * Corporate_ASP_Quantity
		End			List_Price_USD
	, Case 
		When ot.TRANSACTION_TYPE_NAME like 'MTF Transaction%' Then 
			f.COMM_SELLING_AMOUNT_USD
		Else UNIT_SELLING_PRICE_USD * Corporate_ASP_Quantity
		End			Selling_Price_USD
	, f.COMM_SELLING_AMOUNT_TRANSACTIONAL
	, f.COMM_SELLING_AMOUNT_USD
	, f.INVOICE_SELLING_AMOUNT_TRANSACTIONAL
	, f.INVOICE_SELLING_AMOUNT_USD
	, f.FINANCIAL_SELLING_AMOUNT_TRANSACTIONAL
	, f.FINANCIAL_SELLING_AMOUNT_USD
	, Corporate_ASP_Quantity
	, Invoiced_Quantity
	, Case When UNIT_LIST_PRICE_LOCAL <> 0
				And UNIT_SELLING_PRICE_TRANSACTIONAL <> 0
				And Corporate_ASP_Quantity > 0 Then 1
			Else 0 End Sales_Counted
	, Case When UNIT_LIST_PRICE_LOCAL <> 0
				And UNIT_SELLING_PRICE_TRANSACTIONAL <> 0
				And UNIT_LIST_PRICE_LOCAL <> UNIT_SELLING_PRICE_TRANSACTIONAL
				And Corporate_ASP_Quantity > 0 Then 1
			Else 0 End Number_Discounted
	, Case When UNIT_LIST_PRICE_LOCAL <> 0
				And UNIT_SELLING_PRICE_TRANSACTIONAL <> 0
				And UNIT_LIST_PRICE_LOCAL <> UNIT_SELLING_PRICE_TRANSACTIONAL
				And Corporate_ASP_Quantity > 0 Then
					Corporate_ASP_Quantity * (UNIT_LIST_PRICE_LOCAL - UNIT_SELLING_PRICE_TRANSACTIONAL)
			   Else 0
			 End Discount_Local
	, Case When UNIT_LIST_PRICE_LOCAL <> 0
				And UNIT_SELLING_PRICE_TRANSACTIONAL <> 0
				And UNIT_LIST_PRICE_LOCAL <> UNIT_SELLING_PRICE_TRANSACTIONAL
				And Corporate_ASP_Quantity > 0 Then
					Corporate_ASP_Quantity * (UNIT_LIST_PRICE_USD -   Unit_SELLING_Price_USD)
			   Else 0
			 End Discount_USD
	, Case 
			When [Dim_ORDER_SOURCE_SYSTEM_KEY] = 1 And 
				 [Dim_Direct_Trace_KEY] = 2 Then [ORDERED_QUANTITY] 
			Else INVOICED_QUANTITY
		End Traced_Quantity
from AS_dwh.edw.fact_Sales_Order f 

Left Join as_dwh.dbo.timemaster cd
on f.[Dim_COMM_SALES_KEY] = cd. dayid
left Join as_dwh.edw.Dim_Contract_Customer c
on c.Dim_Ship_to_Customer_location_Key = f.Dim_Ship_to_Customer_location_Key
left Join as_dwh.edw.Dim_Contracts_Reporting r
on r.Dim_Customer_location_Key = f.Dim_Ship_to_Customer_location_Key
left Join as_dwh.edw.Dim_Product_Pricelist pp
on pp.Dim_Product_Key = f.Dim_Product_Key
And pp.Dim_Product_Pricelist_Key = f.Dim_PRICE_LIST_KEY
Inner Join as_dwh.dbo.Dim_ORDER_TYPE ot
on f.Dim_ORDER_Header_TYPE_key = ot.Dim_ORDER_TYPE_key

Where cd.ActualDate >= @StartDate
--And Corporate_ASP_Quantity <> 0
--And Dim_Order_Source_System_Key in (1, 4)
