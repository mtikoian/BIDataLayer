USE [AS_DWH]
GO

/****** Object:  View [EDW].[Dim_PRODUCT_Combined_V]    Script Date: 5/2/2018 1:00:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





Alter view [EDW].[Dim_PRODUCT_Combined_V]
as (
SELECT  p1.[Dim_PRODUCT_KEY]
      , p1.[ORACLE_INVENTORY_ITEM_ID]
      , p1.[ORACLE_ORGANIZATION_ID]
      , p1.[ITEM_NUMBER]
      , p1.[GS_ITEM_NUMBER]
      , Cast(p1.[DESCRIPTION] as varchar(100)) Description
      , Cast(p1.[ITEM_NUMBER_DESC] as varchar(100)) ITEM_NUMBER_DESC
      , p1.[List_Price_Per_Unit]
      , p1.[Material_Cost]
      , p1.[Material_Overhead_Cost]
      , p1.[DIM_CONMED_SALES_MARKETING_CATEGORY_KEY]
      , p1.[Dim_BRAND_SALES_CATEGORY_KEY]
      , p1.[DIM_CONMED_ITEM_CATEGORY_KEY]
      , p1.[Dim_LINVATEC_Item_type_CATEGORY_KEY]
      , COALESCE(p1.SALES_ACCOUNT, '0000') SALES_ACCOUNT
      , Unit_Cost
      , ITEM_TYPE
      , PLANNING_MAKE_BUY_CODE
      , PLANNER_CODE
      , Buyer_ID
      , pr.Dim_LINVATEC_FORECAST_CATEGORY_KEY Dim_FORECAST_ITEM_CATEGORY_KEY
      , pr.Dim_LINVATEC_SUPPLY_CHAIN_SOURCING_KEY
      , pr.Dim_STERILE_ITEM_CATEGORY_KEY
      , pr.Dim_RRP_ITEM_CATEGORY_KEY
      , pr.Dim_INVENTORY_ITEM_CATEGORY_KEY
      , pr.[DIM_CONMED_ITEM_CATEGORY_KEY]  [DIM_QUALITY_ITEM_CATEGORY_KEY]
      , pr.[Dim_SOURCE_MANUFACTURING_ITEM_CATEGORY_Key]
	  , pr.Dim_LINVATEC_SALES_COMPLIANCE_CATEGORY_KEY
      , 0 MANUFACTURING_LOCATION
      , 0 SELLABLE_IND
	  , PRIMARY_UOM_CODE
	  , INVENTORY_ITEM_STATUS_CODE
	  , Cast(Design_Owner as varchar(30)) Design_Owner
	  , Cast(origin_Country as varchar(30)) origin_Country
	  , GETDATE() LAUNCH_DATE
      , Coalesce(mp.GL_ProductType, 'NA') GL_ProductType
	  , Coalesce(mp.PfamCode, 'Undefined') PfamCode
	  , Coalesce(mp.PlinCode, 'Undefined') PlinCode
	  , 0 Dim_Vendor_Key 
	  , '155' Default_Shipping_ORG
	  , 'Other' M_Group
	  , '2000/01/01' Revision_Date
	  , ' '			 Previous_Revision
	  , ' '			 Revision
	  , Conversion_Factor
	  , 1 [LOT_CONTROL_CODE]
	  , 1 [SERIAL_NUMBER_CONTROL_CODE]
	  , 'NA' Lot_Serial_Controlled
	  , Coalesce(io.ORGANIZATION_CODE, 'UNK') ORGANIZATION_CODE
	  , Coalesce(io.name, 'Unknown')		  Organization_Name
  FROM [AS_DWH].[EDW].[GS_Dim_PRODUCT] p1
  Left join [AS_DWH].edw.[Manman_DimProducts] mp
  on rtrim(mp.ItemNumber) = rtrim(p1.GS_Item_Number)
  Left join [AS_dwh].[dbo].[Dim_Product] PR
  on p1.Item_Number = pr.Item_Number
  And pr.ORACLE_ORGANIZATION_ID = 155
  Left Join as_dwh.dbo.Dim_Inventory_Organization io
  on p1.ORACLE_ORGANIZATION_ID = io.ORACLE_ORGANIZATION_ID
    
  Union All
  
  SELECT p1.[Dim_PRODUCT_KEY]
      ,p1.[ORACLE_INVENTORY_ITEM_ID]
      ,p1.[ORACLE_ORGANIZATION_ID]
      ,p1.[ITEM_NUMBER]
      ,p1.[ITEM_NUMBER] [GS_ITEM_NUMBER]
      ,Cast(p1.[DESCRIPTION] as varchar(100)) Description
      ,Cast(p1.[ITEM_NUMBER_DESC] as varchar(100)) ITEM_NUMBER_DESC
      ,p1.[List_Price_Per_Unit]
      ,p1.[Material_Cost]
      ,p1.[Material_Overhead_Cost]
      ,p1.[DIM_CONMED_SALES_MARKETING_CATEGORY_KEY]
      ,p1.[Dim_BRAND_SALES_CATEGORY_KEY]
      ,p1.[DIM_CONMED_ITEM_CATEGORY_KEY]
      ,p1.[Dim_LINVATEC_Item_type_CATEGORY_KEY]
      ,P1.SALES_ACCOUNT
      ,p1.Unit_Cost
      ,Coalesce(p1.ITEM_TYPE, ' ') ITEM_TYPE
      ,Coalesce(p1.PLANNING_MAKE_BUY_CODE, ' ') PLANNING_MAKE_BUY_CODE
      ,Coalesce(p1.PLANNER_CODE, ' ') PLANNER_CODE
      ,Coalesce(p1.Buyer_ID, 0) Buyer_ID
      ,Coalesce(p1.Dim_LINVATEC_FORECAST_CATEGORY_KEY, 0) Dim_FORECAST_ITEM_CATEGORY_KEY
      ,Coalesce(p1.Dim_LINVATEC_SUPPLY_CHAIN_SOURCING_KEY, 0) Dim_LINVATEC_SUPPLY_CHAIN_SOURCING_KEY
      ,Coalesce(p1.Dim_STERILE_ITEM_CATEGORY_KEY, 0) Dim_STERILE_ITEM_CATEGORY_KEY
      ,Coalesce(p1.Dim_RRP_ITEM_CATEGORY_KEY, 0) Dim_RRP_ITEM_CATEGORY_KEY
      ,Coalesce(p1.Dim_INVENTORY_ITEM_CATEGORY_KEY, 0) Dim_INVENTORY_ITEM_CATEGORY_KEY
      
      ,Coalesce(p1.[DIM_CONMED_ITEM_CATEGORY_KEY], 0)  [DIM_QUALITY_ITEM_CATEGORY_KEY]
      ,Coalesce(p1.[Dim_SOURCE_MANUFACTURING_ITEM_CATEGORY_Key], 0)  [Dim_SOURCE_MANUFACTURING_ITEM_CATEGORY_Key]
	  , Coalesce(p1.Dim_LINVATEC_SALES_COMPLIANCE_CATEGORY_KEY, 0) Dim_LINVATEC_SALES_COMPLIANCE_CATEGORY_KEY
      , 0 MANUFACTURING_LOCATION
      , CASE WHEN PATINDEX('%Finished Good%', ITEM_TYPE) > 0 and [PLANNING_MAKE_BUY_CODE] = 'Make' then 1 
		ELSE 0    END SELLABLE_IND
	  , PRIMARY_UOM_CODE
	  , INVENTORY_ITEM_STATUS_CODE
	  , Cast(Design_Owner  as varchar(30)) Design_Owner
	  , Cast(origin_Country as varchar(30)) origin_Country
	  , LAUNCH_DATE
	  ,Coalesce(p1.GL_ProductType, 'NA')
	  ,Coalesce(p1.PfamCode, 'Undefined') 
	  ,Coalesce(p1.PlinCode, 'Undefined')
      , p1.dim_vendor_Key
      , p1.Default_Shipping_ORG
      , Cast(Coalesce(r.M_Group,'Other') as varchar(30)) M_Group
      , RevisionDate				Revision_Date
	  , PreviousRevision			 Previous_Revision
	  , Revision
	   ,Conversion_Factor
	   , [LOT_CONTROL_CODE]
	  ,  [SERIAL_NUMBER_CONTROL_CODE]
	  , Case
			When [LOT_CONTROL_CODE]  = 0 And [SERIAL_NUMBER_CONTROL_CODE]  = 0 Then 'Undefined'
			When [LOT_CONTROL_CODE] <> 1 And [SERIAL_NUMBER_CONTROL_CODE] <> 1 Then 'Both'
			When [LOT_CONTROL_CODE] <> 1 Then 'Lot'
			When [SERIAL_NUMBER_CONTROL_CODE] <> 1 Then 'Serial'
			Else 'Neither'
	    End Lot_Serial_Controlled
	  , Coalesce(io.ORGANIZATION_CODE, 'UNK') ORGANIZATION_CODE
	  , Coalesce(io.name, 'Unknown')		  Organization_Name
  FROM [AS_DWH].[dbo].[Dim_PRODUCT] p1
  left join [AS_DWH].[EDW].[GS_Dim_PRODUCT] p2
  on p1.ITEM_NUMBER = p2.GS_ITEM_NUMBER
  and p1.ORACLE_Organization_ID = 155
  Left join as_dwh.LU.Sales_Force_Rankings r
  on p1.Item_Number = r.Item_Number
  Left Join as_dwh.dbo.Dim_Inventory_Organization io
  on p1.ORACLE_ORGANIZATION_ID = io.ORACLE_ORGANIZATION_ID
  Where p2.ITEM_NUMBER is Null

 
  
  Union All
  
  SELECT p1.[Dim_PRODUCT_KEY]
      ,p1.[ORACLE_INVENTORY_ITEM_ID]
      ,p1.[ORACLE_ORGANIZATION_ID]
      ,p1.[ITEM_NUMBER]
      ,p1.[ITEM_NUMBER] [GS_ITEM_NUMBER]
      ,Cast(p1.[DESCRIPTION] as varchar(100)) Description
      ,Cast(p1.[ITEM_NUMBER_DESC] as varchar(100)) ITEM_NUMBER_DESC
      ,p1.[List_Price_Per_Unit]
      ,p1.[Material_Cost]
      ,p1.[Material_Overhead_Cost]
      ,p1.[DIM_CONMED_SALES_MARKETING_CATEGORY_KEY]
      ,p1.[Dim_BRAND_SALES_CATEGORY_KEY]
      ,p1.[DIM_CONMED_ITEM_CATEGORY_KEY]
      ,p1.[Dim_LINVATEC_Item_type_CATEGORY_KEY]
      , '0000' SALES_ACCOUNT
      ,0 Unit_Cost
      , ' ' ITEM_TYPE
      , ' ' PLANNING_MAKE_BUY_CODE
      , ' ' PLANNER_CODE
      , 0 Buyer_ID
      , 0 Dim_FORECAST_ITEM_CATEGORY_KEY
      , 0 Dim_LINVATEC_SUPPLY_CHAIN_SOURCING_KEY
      , 0 Dim_STERILE_ITEM_CATEGORY_KEY
      , 0 Dim_RRP_ITEM_CATEGORY_KEY
      , 0 Dim_INVENTORY_ITEM_CATEGORY_KEY
      , p1.[DIM_CONMED_ITEM_CATEGORY_KEY]  [DIM_QUALITY_ITEM_CATEGORY_KEY]
      , 0 [Dim_SOURCE_MANUFACTURING_ITEM_CATEGORY_Key]
	  , 0 Dim_LINVATEC_SALES_COMPLIANCE_CATEGORY_KEY
      , 0 MANUFACTURING_LOCATION
      , 0 SELLABLE_IND
	  , ' ' PRIMARY_UOM_CODE
	  , ' ' INVENTORY_ITEM_STATUS_CODE
	  , ' ' Design_Owner
	  , ' ' origin_Country
	  , GETDATE() LAUNCH_DATE
	  ,Coalesce(mp.GL_ProductType, 'NA')
	  ,Coalesce(mp.PfamCode, 'Undefined') 
	  ,Coalesce(mp.PlinCode, 'Undefined')
	  , 0 Dim_Vendor_Key 
	  , '155' Default_Shipping_ORG
	  , 'Other' M_Group
	  , '2000/01/01' Revision_Date
	  , ' '			 Previous_Revision
	  , ' '			Revision
	  , 1			 Conversion_Factor
	  , 1 [LOT_CONTROL_CODE]
	  , 1 [SERIAL_NUMBER_CONTROL_CODE]
	  , 'NA' Lot_Serial_Controlled
	  , Coalesce(io.ORGANIZATION_CODE, 'UNK') ORGANIZATION_CODE
	  , Coalesce(io.name, 'Unknown')		  Organization_Name
  FROM [AS_DWH].edw.[MISSING_DIM_PRODUCT] p1
  Left join [AS_DWH].edw.[Manman_DimProducts] mp
  on rtrim(mp.ItemNumber) = p1.GS_Item_Number
  Left join [AS_DWH].dbo.[DIM_PRODUCT] p
  on p1.ITEM_NUMBER = p.ITEM_NUMBER
  and p1.ORACLE_ORGANIZATION_ID = p.ORACLE_ORGANIZATION_ID
  Left Join as_dwh.dbo.Dim_Inventory_Organization io
  on p1.ORACLE_ORGANIZATION_ID = io.ORACLE_ORGANIZATION_ID
  Where p.ITEM_NUMBER is null
  
)





































GO


