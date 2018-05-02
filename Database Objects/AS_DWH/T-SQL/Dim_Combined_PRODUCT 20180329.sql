-- Dim_Combined_PRODUCT

Truncate Table [AS_stage].[dbo].[STG_Dim_Combined_PRODUCT_FK]
Insert INTO  [AS_stage].[dbo].[STG_Dim_Combined_PRODUCT_FK]

SELECT [ITEM_NUMBER] 
	, Max(sc.STERILE) STERILE
      , Max(sc.METHOD) METHOD
	  , Max(p.Dim_STERILE_ITEM_CATEGORY_Key) Dim_STERILE_ITEM_CATEGORY_Key
FROM [AS_DWH].dbo.[Dim_PRODUCT] p
Inner join [AS_DWH].[dbo].Dim_STERILE_ITEM_CATEGORY sc
on p.[Dim_STERILE_ITEM_CATEGORY_Key] = sc.Dim_STERILE_ITEM_CATEGORY_KEY
Where ORACLE_ORGANIZATION_ID = 155
Group by ITEM_NUMBER

USE [AS_dwh]
GO

truncate table [AS_DWH].[dbo].[Dim_Combined_PRODUCT]

Insert into [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
 
  SELECT p.[Dim_PRODUCT_KEY]
      , p.Dim_Vendor_Key
      , 1 Dim_PUR_ORG_KEY
      , p.ORACLE_ORGANIZATION_ID
      , p.DESCRIPTION
      , p.ITEM_NUMBER
      , coalesce(b.full_name, 'Unknown') [Buyer]
      , p.PLANNING_ABC_CLASS_NAME
      , p.FIXED_DAYS_SUPPLY
      , p.FIXED_LEAD_TIME
      , p.FULL_LEAD_TIME
      , p.PLANNING_MAKE_BUY_CODE
      , p.Dim_PLANNER_KEY
      , pl.PLANNER_Code
      , p.Revision
      , 0 PRTOPC
      , 0 PRTCC
      , p.SAFETY_STOCK_QUANTITY
      , p.[Unit_Cost] [FullSTDCost]
      , p.[UNIT_PRICE] [LastInvUnitCost]
      , p.Material_Cost Material_Cost

      , p.PLANNING_MAKE_BUY_CODE [MakeBuy_Desc]
      , p.[ITEM_TYPE] [OPC_Desc]
      , p.[ITEM_TYPE] [PRTtyp]
      , p.PRIMARY_UOM_CODE		PurchaseUOM
      , p.PRIMARY_UOM_CODE		StockingUOM
      , 1						ConversionFactor
      , p.Actual_Usage ActualUsage
      , p.Dim_Product_Smoothie_Key
      , Coalesce(p.Default_Shipping_Org, 'Unknown') Default_Shipping_Org
      , ric.rrp_Source			Factory
      , p.INVENTORY_ITEM_STATUS_CODE Product_Status
      , p.[RevisionDate]
	  , p.[PreviousRevision]
	  , pl.FULL_NAME			Planner_Name
	  , ' '						Buyer_Code
	  , p.FIXED_LOT_MULTIPLIER  Order_Increment_Qty
	  , Case 
			When s.STERILE Is Null Then 'No'
			When s.STERILE in ('Y', 'Yes') Then 'Yes'
			When s.STERILE in ('N', 'No') Then 'No'
			Else 'No' End STERILE_Flag
	  , Case 
			When p.[INVENTORY_ITEM_STATUS_CODE] in ('Active', 'ACTIVE-NO', 'RunOut') Then 'Yes'
			Else 'No' End Sellable_Good_Indicator
	  , p.MINIMUM_ORDER_QUANTITY
	  , p.MIN_MINMAX_QUANTITY
	  , p.MAX_MINMAX_QUANTITY
	  , Coalesce(pc.[Dim_LINVATEC_FORECAST_CATEGORY_KEY],0) Dim_FORECAST_ITEM_CATEGORY_KEY
	  , 0 LAST_PO_UNIT_COST
	  , 'N/A' Manman_Intercompany_Item
  FROM [AS_DWH].[dbo].[Dim_PRODUCT] p
  left outer join as_dwh.dbo.Dim_BUYER b
  on p.Dim_Buyer_Key = b.Dim_Buyer_Key
  left outer join as_dwh.dbo.Dim_PLANNER pl
  on p.Dim_Planner_Key = pl.Dim_Planner_Key
  inner join as_dwh.dbo.Dim_RRP_ITEM_CATEGORY ric
  on p.Dim_RRP_ITEM_CATEGORY_KEY = ric.Dim_RRP_ITEM_CATEGORY_KEY 
  Left join [AS_stage].[dbo].[STG_Dim_Combined_PRODUCT_FK] s
  on p.item_number = s.Item_Number
      
  Left Join [AS_DWH].[dbo].[Dim_PRODUCT] pc
  on p.ITEM_NUMBER = pc.ITEM_NUMBER
  And pc.ORACLE_ORGANIZATION_ID = 155
  
  --WHERE p.ORACLE_ORGANIZATION_ID in 
		--(356, 358, 591, 363, 372, 375, 168, 772, 155) 
	--And p.INVENTORY_ITEM_STATUS_CODE  not in
	--	('Obsolete', 'Inactive')
	--And p.ITEM_TYPE  not in 
	--	('Charge Items', 'Extended Warranty', 'Freight', 'Reference Item', 'Service Agreement')


Union All


SELECT p.[Dim_Product_ManMan_KEY]
	  , p.Dim_ManMan_Vendor_Key
      , p.Dim_PUR_ORG_KEY
      , 0 ORACLE_ORGANIZATION_ID
      , p.[PartDesc]	Description
      , p.[PartNumber]	[ITEM_NUMBER]
      , p.Buyer_Name
      , p.[ABCClass]
      , p.[FixedDaysSupply]
      , p.[FixedLeadTime]
      , p.[ItemProcessingLeadTime]
      , p.[MakeBuy]
      , 0 Dim_PLANNER_KEY
      , p.[PlannerCode]
      , p.[Revision]
      , p.[PRTOPC]
      , p.[PRTCC]
      , p.[PRTSS]
      , p.[FullSTDCost]
      , p.[LastInvUnitCOst]
      , p.[MatSTDCost]
      , p.[MakeBuy_Desc]
      , p.[OPC_Desc]
      , Case
			When p.PRTOPC = 4 And MakeBuy in ('E', 'F', 'P') Then 'Finished Good - Buy'
			When p.PRTOPC = 4 And MakeBuy in ('M', 'MS') Then 'Finished Good - Make'
			When p.PRTOPC <> 4 And MakeBuy in ('F', 'P') Then 'Component Item - Buy'
			When p.PRTOPC <> 4 And MakeBuy in ('M', 'MS') Then 'Subassembly'
			When p.MakeBuy in ('X') Then 'Phantom item'
			When p.MakeBuy in ('B') Then 'Component Item - Buy'
			When p.MakeBuy in ('R#', 'R', 'UU') Then 'Reference'
			When p.MakeBuy in ('E', 'E*', 'EA', 'PE', 'E#') Then 'Expense'
			Else 'Other'
	    End [PRTtyp]
      , p.PurchaseUOM
      , p.StockingUOM
      , p.ConversionFactor
      , 0 Actual_Usage -- Updated Below
      , p.Dim_Product_Smoothie_Key
      , 'XXX'  Default_Shipping_Location
      , s.Factory
      , p.PRTactstat  Product_Status
      , Case 
			When p.[RevisionDate] = 0 Then Cast('01/01/2000' as Datetime2)
			When p.[RevisionDate] = 99999999 Then Cast('01/01/2000' as Datetime2)
			Else Cast(Cast(p.[RevisionDate] as Varchar) As Datetime2)
		End [RevisionDate]
      , p.[PreviousRevision]
      , p.Planner_Name
	  , p.Buyer					Buyer_Code
	  , p.PRTPAN
	  , Case 
			When p.Sterile_Flag = 1 Then 'Yes'
			Else 'No' End STERILE_Flag
	  , Case 
			When p.Sellable_Good_Indicator = 1 Then 'Yes'
			Else 'No' End Sellable_Good_Indicator
	  , PRTMOQ
	  , 0	Min_MinMax_Quantity
	  , 0	Max_MinMan_Quantity
	  , Coalesce(pc.Dim_FORECAST_ITEM_CATEGORY_KEY,0) Dim_FORECAST_ITEM_CATEGORY_KEY
	  , 0 LAST_PO_UNIT_COST
	  , 'N' Manman_Intercompany_Item
  FROM [AS_DWH].[dbo].[Dim_Product_ManMan_v] p
  --left outer join [AS_STAGE].[dbo].[LU_ManMan_Buyer] b
  --on p.Buyer = b.[buyer code]
  left outer join [AS_DWH].[dbo].[Dim_Product_Smoothie] s
  on p.Dim_Product_Smoothie_Key = s.Dim_Product_Smoothie_Key
    
  Left Join [AS_DWH].edw.[Dim_PRODUCT_Combined_V] pc
  on rtrim(p.PartNumber) = pc.gs_ITEM_NUMBER
  And pc.ORACLE_ORGANIZATION_ID = 155
  
	TRUNCATE TABLE AS_STAGE.DBO.STG_MANMAN_ACTUAL_USAGE

	INSERT INTO AS_STAGE.DBO.STG_MANMAN_ACTUAL_USAGE

		SELECT 
			f.[dim_product_Manman_key]
			,Sum([ActualUsage]) asum
		FROM [AS_DWH].[dbo].[Fact_MRP_Manman] f
		group by f.[dim_product_ManMan_key]
  
  update [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
	set ActualUsage = u.[ASum]
  FROM [Dim_Combined_PRODUCT] p
  INNER JOIN AS_STAGE.DBO.STG_MANMAN_ACTUAL_USAGE U
  on u.dim_product_ManMan_key = p.Dim_Product_KEY

  Update [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
	Set Default_Shipping_org = coalesce(p.Default_Shipping_org, 'Unknown')
  from [AS_DWH].[dbo].[Dim_Combined_PRODUCT] cp
  Inner Join [AS_DWH].edw.[Dim_PRODUCT_Combined_v] p
  on cp.Item_Number = p.gs_item_Number
  And cp.ORACLE_ORGANIZATION_ID = 0 
  And p.ORACLE_ORGANIZATION_ID = 155
    
    update [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
	set fixed_days_supply = 0
  Where fixed_days_supply is null
  
    update [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
	set [FIXED_LEAD_TIME] = 0
  Where [FIXED_LEAD_TIME] is null
  
    update [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
	set [FULL_LEAD_TIME] = 0
  Where [FULL_LEAD_TIME] is null
  
  
    update [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
	set [Revision] = 0
  Where [Revision] is null
  
  
    update [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
	set [FullSTDCost] = 0
  Where [FullSTDCost] is null
  
    update [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
	set [LastInvUnitCost] = 0
  Where [LastInvUnitCost] is null
  
    update [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
	set [Material_Cost] = 0
  Where [Material_Cost] is null
  
    update [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
	set MINIMUM_ORDER_QUANTITY = 0
  Where MINIMUM_ORDER_QUANTITY is null

   update [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
	set Order_Increment_Qty = 0
  Where Order_Increment_Qty is null

  update [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
	set MIN_MINMAX_QUANTITY = 0
  Where MIN_MINMAX_QUANTITY is null

  update [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
	set MAX_MINMAX_QUANTITY = 0
  Where MAX_MINMAX_QUANTITY is null	


  -- Add Last PO Unit Cost from Invoice Detail Merge Cube Fact table
  Truncate Table as_Stage.dbo.stg_Dim_Combined_Product_PO_Cost
  Insert Into as_Stage.dbo.stg_Dim_Combined_Product_PO_Cost
  SELECT  Max(Coalesce(S_POUnitPrice,0)) S_POUnitPrice
		, f.dim_VoucherDate_key
		, f.Dim_Receipt_PartNum_Key
		, f.Dim_PUR_ORG_KEY
		, f.Dim_Inventory_Organization_Key
		, c.Dim_Product_Key
  FROM as_dwh.dbo.FACT_INVOICE_MERGE f
  Inner Join
	(SELECT   Dim_Inventory_Organization_Key 
		, Dim_PUR_ORG_KEY
		, Dim_Receipt_PartNum_Key
		, Max(dim_VoucherDate_key) dim_VoucherDate_key
	FROM as_dwh.dbo.FACT_INVOICE_MERGE f
	Group by Dim_Inventory_Organization_Key 
		, Dim_PUR_ORG_KEY
		, Dim_Receipt_PartNum_Key) M
  on f.dim_VoucherDate_key = m.dim_VoucherDate_key
  And f.Dim_Receipt_PartNum_Key = m.Dim_Receipt_PartNum_Key
  And f.Dim_PUR_ORG_KEY = m.Dim_PUR_ORG_KEY
  And f.Dim_Inventory_Organization_Key = m.Dim_Inventory_Organization_Key
  inner join Dim_Product_Combined_Invoice p
  on f.Dim_Receipt_PartNum_Key = p.Dim_PRODUCT_KEY
  inner join Dim_Inventory_Organization io
  on f.Dim_Inventory_Organization_Key = io.Dim_Inventory_Organization_Key
  inner join as_dwh.dbo.Dim_Combined_Product c
  on p.Item_Number = c.Item_Number
  And io.Oracle_Organization_ID = c.Oracle_Organization_ID
  And f.Dim_PUR_ORG_KEY = c.Dim_PUR_ORG_KEY 
  Where Coalesce(S_POUnitPrice,0) > 0
  Group by f.dim_VoucherDate_key
		, f.Dim_Inventory_Organization_Key
		, f.Dim_Receipt_PartNum_Key
		, f.Dim_PUR_ORG_KEY
		, c.Dim_Product_Key

  Update as_dwh.dbo.Dim_Combined_Product
	Set LAST_PO_UNIT_COST = s.S_POUnitPrice / ConversionFactor
  From as_dwh.dbo.Dim_Combined_Product c
  Inner Join as_Stage.dbo.stg_Dim_Combined_Product_PO_Cost s
  on c.Dim_Product_Key = s.Dim_Product_Key


  -- Add Manman Intercompany Item column
  Truncate Table as_stage.dbo.stg_Manman_Intercompany_Items_Forecast
  Insert Into as_stage.dbo.stg_Manman_Intercompany_Items_Forecast
  Select o.Dim_PUR_ORG_KEY
	, p.ITEM_NUMBER
	, LU.DESCRIPTION
	, LU.LOOKUP_CODE
	, 'Y' Manman_Intercompany_Item
  from as_dwh.dbo.Dim_Combined_PRODUCT p
  Inner Join as_dwh.dbo.Dim_Pur_Org o
  on p.Dim_Pur_Org_key = o.Dim_Pur_Org_key
  Left Join dw_Main.dbo.FND_LOOKUP_VALUES_VL LU
  on o.PUR_ORG_SITE = LU.DESCRIPTION
  And p.ITEM_NUMBER = LU.LOOKUP_CODE
  Where Case
		When o.PUR_ORG_SITE = 'Largo' Then 'N/A'
		When LU.LOOKUP_CODE IS NULL Then 'N'
		Else 'Y'
	  End = 'Y'

  Update [AS_DWH].[dbo].[Dim_Combined_PRODUCT]
	Set Manman_Intercompany_Item = s.Manman_Intercompany_Item
  From [AS_DWH].[dbo].[Dim_Combined_PRODUCT] p
  Inner Join as_stage.dbo.stg_Manman_Intercompany_Items_Forecast s
  on p.ITEM_NUMBER = s.LOOKUP_CODE
  And p.Dim_PUR_ORG_KEY = s.Dim_PUR_ORG_KEY
