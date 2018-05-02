-- Load Ortho Open Orders

Insert Into as_dwh.EDW.Fact_SALES_Open_Order

Select Coalesce(od.dayid, -1)		[Dim_ORDERED_DATE_KEY], 
		Coalesce(ssd.dayid, -1)		[Dim_SCH_SHIP_DATE_KEY],
		[Dim_OPERATING_UNIT_KEY]	[Dim_OPERATING_UNIT_KEY], 
		0							[Dim_ORDER_HEADER_TYPE_KEY], 
		0							[Dim_ORDER_LINE_TYPE_KEY],
		Coalesce(Dim_Customer_location_Key,0)	[Dim_SHIP_TO_CUSTOMER_LOCATION_KEY],  
		Coalesce(Dim_Customer_Key,0)			[Dim_SHIP_TO_CUSTOMER_KEY], 
		Coalesce(p.Dim_product_Key, 0)			[Dim_PRODUCT_KEY], 
		Coalesce(g.Dim_SALES_GEOGRAPHY_KEY , 0)	[Dim_SALES_GEOGRAPHY_KEY], 
		1 										[Dim_ORDER_SOURCE_SYSTEM_KEY], 
		Coalesce(H.Dim_HOLD_STATUS_KEY , 0)		Dim_HOLD_STATUS_KEY,
		Coalesce(o.Dim_Order_KEY , 0)			Dim_ORDER_KEY,
		Coalesce(Dim_Commission_Status_Key, 0)	Dim_Commission_Status_Key,

		f.Order_Number			[ORDER_NUMBER], 
		f.order_Line_Num		[ORACLE_ORDER_LINE_ID], 
		f.order_Line_Num		[LINE_NUMBER], 

		[CONTRACT_NUMBER]		[CONTRACT_NUMBER], 
		f.Cust_PO_Number		[CUST_PO_NUMBER],  
		f.Invoice_Line_Num		[INVOICE_LINE_ID], 
		f.Order_Revision		[ORDER_REVISION], 
		[FLOW_STATUS_CODE]		[FLOW_STATUS_CODE], 

		f.Invoice_Curr_Code		[FUNCTIONAL_CURRENCY_CODE], 
		f.Invoice_Curr_Code		[TRANSACTIONAL_CURRENCY_CODE], 

		f.Quantity_Ordered		[ORDERED_QUANTITY], 
		f.Quantity_Shipped		[SHIPPED_QUANTITY], 
		f.Quantity_Invoiced		[INVOICED_QUANTITY], 

		f.Ord_Line_Amt_USD, 
		f.Order_Line_Amt,
		Coalesce(pl.Dim_PRICELIST_KEY, -1) Dim_PRICELIST_KEY, 
		Coalesce(glc.Dim_GL_Company_Hierarchy_KEY,0) Dim_GL_Company_Hierarchy_KEY
			
		
From [AS_DWH].dbo.Sales_Open_Orders_Stars_Format_Combined f
left join as_dwh.dbo.Dim_Product p
on f.Item_Number = p.Item_Number
and p.Oracle_Organization_Id = f.Inv_Org_ID

left join as_dwh.edw.Dim_Operating_Unit_V ou
on f.Operating_Unit = ou.NAME

left join as_dwh.dbo.Dim_SALES_GEOGRAPHY g
on f.repnum2 = g.GEOGID

left join as_dwh.dbo.TimeMaster od
on CAST(f.Ordered_Date AS DATE) = od.ActualDate

left join as_dwh.dbo.TimeMaster ssd
on SCHEDULED_SHIP_DATE = ssd.ActualDate
			
Inner join as_dwh.[dbo].[Dim_CUSTOMER] c
on f.Oracle_Cust_Num = c.Account_Number

Inner Join as_dwh.[dbo].[Dim_CUSTOMER_Location] cl
on f.ShipTo_Site_Use_ID = cl.ORACLE_SITE_USE_ID

left join [AS_DWH].[EDW].[Dim_HOLD_STATUS] h
  on f.Hold_Type = h.[HOLD_STATUS]
   
left join [AS_DWH].[EDW].Dim_ORDER o
  on f.Order_Number = o.Order_Number
  
left join [AS_DWH].[EDW].[Dim_Commission_Status] cs
  on Case 
		When Commissionable_Flag = 'Y' Then 'Yes'
		When Commissionable_Flag = 'N' Then 'No'
		Else 'Unk'
	End  = cs.Commission_Status

left join as_dwh.EDW.[Dim_PRICELIST] pl
on f.Price_List_Name = pl.Name

left join as_dwh.[EDW].[Dim_GL_Company_Hierarchy] glc
on f.Company = glc.gl_Company

Where f.Org_id is Not Null	

