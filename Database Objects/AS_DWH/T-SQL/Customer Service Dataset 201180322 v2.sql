-- Customer Service Dataset

-- Stage Order Fulfillment Data
Truncate Table AS_Stage.dbo.Stg_Release_To_Warehouse_Date
Insert Into AS_Stage.dbo.Stg_Release_To_Warehouse_Date

Select  Cast(so.ORDER_NUMBER  as nvarchar(150))
		, sol.LINE_NUMBER
		, Cast(Left(Cast(Dim_RELEASED_TO_WAREHOUSE_DATE_KEY as Varchar(8)), 4) + '-'
		 + Substring(Cast(Dim_RELEASED_TO_WAREHOUSE_DATE_KEY as Varchar(8)), 5,2) + '-' 
		 + Substring(Cast(Dim_RELEASED_TO_WAREHOUSE_DATE_KEY as Varchar(8)), 7,2) as Date) 
				RELEASED_TO_WAREHOUSE_DATE
		, Cast(Left(Cast([Dim_SCHEDULE_SHIP_DATE_KEY] as Varchar(8)), 4) + '-'
		 + Substring(Cast([Dim_SCHEDULE_SHIP_DATE_KEY] as Varchar(8)), 5,2) + '-' 
		 + Substring(Cast([Dim_SCHEDULE_SHIP_DATE_KEY] as Varchar(8)), 7,2) as Date) 
			Scheduled_Ship_DATE
		, u.USER_NAME
		, Cast(Left(Cast(Dim_ACTUAL_SHIPMENT_DATE_KEY as Varchar(8)), 4) + '-'
		 + Substring(Cast(Dim_ACTUAL_SHIPMENT_DATE_KEY as Varchar(8)), 5,2) + '-' 
		 + Substring(Cast(Dim_ACTUAL_SHIPMENT_DATE_KEY as Varchar(8)), 7,2) as Date) 
			Actual_Ship_DATE
		, Shipped_quantity
from AS_DWH.dbo.FACT_ORDER_FULFILLMENT f
Inner Join AS_DWH.dbo.DIM_SALES_ORDER_LINE sol
On f.DIM_SALES_ORDER_LINE_KEY = sol.DIM_SALES_ORDER_LINE_KEY
Inner Join AS_DWH.dbo.DIM_SALES_ORDER so
on f.DIM_SALES_ORDER_KEY = so.DIM_SALES_ORDER_KEY
Left Join dw_main.dbo.fnd_user u
on u.USER_ID = sol.CREATED_BY
Where Cast(Left(Cast([Dim_SCHEDULE_SHIP_DATE_KEY] as Varchar(8)), 4) + '-'
		 + Substring(Cast([Dim_SCHEDULE_SHIP_DATE_KEY] as Varchar(8)), 5,2) + '-' 
		 + Substring(Cast([Dim_SCHEDULE_SHIP_DATE_KEY] as Varchar(8)), 7,2) as Date) >=
			dateadd(Month, -3, Getdate())
Union All
Select rtrim(Order_Number) Order_Number
	, Cast(Order_line_Number as bigint) Order_line_Number
	, Cast(Released_To_Warehouse_Date as Date) Released_To_Warehouse_Date
	, Cast(Scheduled_Ship_Date as Date) Scheduled_Ship_Date
	, Entered_By
	, ActualShipDate
	, ShippedQuantity
from AS_Stage.[dbo].stg_ManMan_Release_To_Warehouse_Date 


-- Stage Sales Data
Truncate Table AS_Stage.dbo.Stg_Release_To_Warehouse_Sales
Insert Into AS_Stage.dbo.Stg_Release_To_Warehouse_Sales
SELECT Distinct stcl.[Account_Name]
	  , CASE
			WHEN glc.GEOG1_DESCRIPTION = 'Domestic' Then 'Domestic'
			WHEN glc.Export = 'Yes' Then 'Export'
			ELSE 'International' 
		END as customer_type
      , f.Order_number
      , Case
			When os.Source_system_Name = 'OMAR Sales Orders' Then 'Manman' Else io.NAME End	Warehouse
	  , Case
			When os.Source_system_Name = 'OMAR Sales Orders' Then 'Manman' 
			Else io.ORGANIZATION_CODE End	ORGANIZATION_CODE
      , ot.TRANSACTION_TYPE_NAME Order_Type
      , os.SOURCE_SYSTEM_NAME
      , f.LINE_Number
      , p.[GS_Item_Number] [Item_Number]
      , p.[Description]
	  , iic.PRODUCT_TYPE [Item_Type]
      , p.PLANNING_MAKE_BUY_CODE
      , iic.PRODUCT_DESCRIPTION Inventory_Item_Category2
	  , stcl.[CUSTOMER_CLASS_CODE]
  FROM [AS_DWH].edw.[Fact_Sales_Order] f 
  Inner Join [AS_DWH].[EDW].[Dim_CUSTOMER_LOCATION] stcl
  on f.Dim_Ship_To_Customer_Location_Key = stcl.Dim_Customer_Location_Key
  Inner Join as_dwh.edw.Dim_Product_Combined_V p
  on f.Dim_Product_Key = p.Dim_Product_Key
  Inner Join as_dwh.dbo.DIM_Inventory_Item_CATEGORY iic
  on iic.DIM_Inventory_ITEM_CATEGORY_Key = p.DIM_Inventory_ITEM_CATEGORY_Key
  Inner join as_dwh.dbo.Dim_Order_type ot
  on ot.Dim_Order_Type_Key  = f.Dim_Order_Header_Type_Key
  Inner Join as_dwh.edw.Dim_GL_Company_Hierarchy glc
  on f.Dim_GL_Company_Hierarchy_Key = glc.Dim_GL_Company_Hierarchy_Key
  Inner Join as_dwh.dbo.Dim_Inventory_Organization io
  on p.Oracle_Organization_ID = io.Oracle_Organization_ID
  Inner Join as_dwh.edw.Dim_ORDER_SOURCE_SYSTEM os
  on f.Dim_ORDER_SOURCE_SYSTEM_KEY= os.Dim_ORDER_SOURCE_SYSTEM_KEY
  Inner Join as_dwh.dbo.Timemaster sd
  on f.[Dim_ACTUAL_SHIPMENT_DATE_KEY] = sd.dayid

  Where (sd.ActualDate > = dateadd(Month, -3, Getdate()) or sd.ActualDate is null)
  And os.SOURCE_SYSTEM_NAME in ('OMAR Sales Orders', 'Oracle Sales Orders')

  Union ALL

  SELECT Distinct stcl.[Account_Name]
	  , CASE
			WHEN stcl.COUNTRY = 'US' Then 'Domestic'
			ELSE 'International' 
		END as customer_type
      , f.Order_number
      , Case
			When os.Source_system_Name = 'OMAR Sales Orders' Then 'Manman' Else io.NAME End	Warehouse
	  , Case
			When os.Source_system_Name = 'OMAR Sales Orders' Then 'Manman' 
			Else io.ORGANIZATION_CODE End	ORGANIZATION_CODE
      , ot.TRANSACTION_TYPE_NAME Order_Type
      , os.SOURCE_SYSTEM_NAME
      , f.LINE_Number
      , p.[GS_Item_Number] [Item_Number]
      , p.[Description]
	  , iic.PRODUCT_TYPE [Item_Type]
      , p.PLANNING_MAKE_BUY_CODE
      , iic.PRODUCT_DESCRIPTION Inventory_Item_Category2
	  , stcl.[CUSTOMER_CLASS_CODE]
  FROM [AS_DWH].edw.[Fact_Sales_Open_Order] f 
  Inner Join [AS_DWH].[EDW].[Dim_CUSTOMER_LOCATION] stcl
  on f.Dim_Ship_To_Customer_Location_Key = stcl.Dim_Customer_Location_Key
  Inner Join as_dwh.edw.Dim_Product_Combined_V p
  on f.Dim_Product_Key = p.Dim_Product_Key
  Inner Join as_dwh.dbo.DIM_Inventory_Item_CATEGORY iic
  on iic.DIM_Inventory_ITEM_CATEGORY_Key = p.DIM_Inventory_ITEM_CATEGORY_Key
  Inner join as_dwh.dbo.Dim_Order_type ot
  on ot.Dim_Order_Type_Key  = f.Dim_Order_Header_Type_Key
  Inner Join as_dwh.dbo.Dim_Inventory_Organization io
  on p.Oracle_Organization_ID = io.Oracle_Organization_ID
  Inner Join as_dwh.edw.Dim_ORDER_SOURCE_SYSTEM os
  on f.Dim_ORDER_SOURCE_SYSTEM_KEY= os.Dim_ORDER_SOURCE_SYSTEM_KEY



-- Create Final Table
Truncate Table as_dwh.Tableau.Customer_Service_Level_Avail_To_Ship
Insert Into as_dwh.Tableau.Customer_Service_Level_Avail_To_Ship
SELECT Cast(s.Actual_Ship_DATE as Date) Actual_Ship_DATE
	  , Cast(s.Scheduled_Ship_DATE as Date) Scheduled_Ship_DATE
	  , Cast(s.RELEASED_TO_WAREHOUSE_DATE as Date) RELEASED_TO_WAREHOUSE_DATE
      , f.[Account_Name]
	  , Coalesce(f.customer_type, 'Unknown')
      , s.Order_number
      , Coalesce(s.Shipped_Quantity, 0) 
      , Coalesce(f.Warehouse, 'unknown')
	  , Coalesce(f.ORGANIZATION_CODE, 'unknown')
      , Coalesce(f.Order_Type, 'unknown')
      , Coalesce(f.SOURCE_SYSTEM_NAME, 'unknown')
	  , s.USER_NAME 'Entered_by'
      , s.LINE_Number
      , f.Item_Number
      , f.Description
	  , f.Item_Type
      , f.PLANNING_MAKE_BUY_CODE
      , f.Inventory_Item_Category2
	  , f.CUSTOMER_CLASS_CODE
  FROM AS_Stage.dbo.Stg_Release_To_Warehouse_Sales f 
  Inner Join AS_Stage.dbo.Stg_Release_To_Warehouse_Date s
  on f.Order_number = s.Order_number
  And f.LINE_Number = s.LINE_Number

-- Update Oracle Undefineds
Update as_dwh.Tableau.Customer_Service_Level_Avail_To_Ship
	Set Order_Type = DT.TRANSACTION_TYPE_NAME
from as_dwh.Tableau.Customer_Service_Level_Avail_To_Ship s
Inner Join  dw_main.dbo.OE_ORDER_HEADERS_ALL OHA
on cast(Cast(oha.order_number as int) as nvarchar(20)) = s.order_number
Inner join AS_DWH.dbo.Dim_ORDER_TYPE DT
on OHA.ORDER_TYPE_ID = DT.ORACLE_TRANSACTION_TYPE_ID
Where s.Order_Type = 'Undefined'