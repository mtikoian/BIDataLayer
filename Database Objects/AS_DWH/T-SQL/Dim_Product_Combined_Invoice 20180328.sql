-- Dim_Product_Combined_Invoice

USE [AS_STAGE]
GO

-- Create Manman Stage table
Truncate Table [AS_STAGE].[dbo].[Stage_ReceiptPartNum]
INSERT INTO [AS_STAGE].[dbo].[Stage_ReceiptPartNum]
	(
		org
      , ITEM_NUMBER
      , DESCRIPTION
      , FIXED_LEAD_TIME
      , ITEM_NUMBER_DESC
      , PLANNING_MAKE_BUY_CODE
      , PLANNER_CODE    
      , actual_usage
      , ACTUAL_ORDER_QUANTITY
      , GROSS_REQUIREMENT_QUANTITY
      , ON_HAND_QUANTITY
      , PLANNED_ORDER_QUANTITY
      , GROSS_REQUIREMENT_Material_Value_Local
      , GROSS_REQUIREMENT_PO_Unit_Price_Value_Local
      , GROSS_REQUIREMENT_Unit_Value_Local
      , Planned_Order_Material_Value_Local
      , Planned_Order_PO_Unit_Price_Value_Local
      , Planned_Order_Unit_Value_Local
      , CYCLE_ABC_CLASS_NAME
	  , Revision
	  , SAFETY_STOCK_QUANTITY
	  , last_PO_Unit_Price
	  , UNIT_PRICE
	  , Material_Cost
	  , FULL_LEAD_TIME
      )


SELECT  s.org
      , coalesce(s.partnumber, 'Undefined')			partnumber
      , Max(coalesce(partdescription, 'Undefined'))	partdescription
      , Max(coalesce(partfixedleadtime, '0'))		partfixedleadtime
      , s.PartNumber + ' - ' + Max(partdescription) ITEM_NUMBER_DESC
      , Max(coalesce(PartSourceCode, 'UU'))			PartSourceCode
      , Max(coalesce(PlannerCode, 'UU'))			PlannerCode
      
      , Max(coalesce(S_PreviousUsage + S_CurrentUsage,0))												Actual_Usage 
      , Max(coalesce(P_opensupplyreceipts,0))															Open_PO_Quantity
      , Max(coalesce(P_GrossRqmtsTotal,0))																Gross_Requirement_Quantity
      , Max(coalesce(P_QOH,0))																			On_hand_Quantity
	  , Max(coalesce(P_GrossRqmtsTotal - P_QOH - P_opensupplyreceipts,0))								Planned_Order_Quantity
	  
	  --, Max(coalesce(P_GrossRqmtsTotal,0)) * Max(coalesce(j.S_ReceiptStdMatlCost,0))					GROSS_REQUIREMENT_Material_Value_Local
   --   , Max(coalesce(P_GrossRqmtsTotal,0)) * Max(coalesce(j.S_POUnitPrice,0))							GROSS_REQUIREMENT_PO_Unit_Price_Value_Local
   --   , Max(coalesce(P_GrossRqmtsTotal,0)) * Max(coalesce(j.S_InvoicePrice,0))						GROSS_REQUIREMENT_Unit_Value_Local
   
      , Max(P_ExtGrossRqmtsCurrentStdMatlCost)															GROSS_REQUIREMENT_Material_Value_Local
      , Max(P_ExtGrossRqmtsLastPOPrice)																	GROSS_REQUIREMENT_PO_Unit_Price_Value_Local
      , Max(P_ExtGrossRqmtsInvCost)																		GROSS_REQUIREMENT_Unit_Value_Local
      
      
      , Max(coalesce(P_GrossRqmtsTotal - P_QOH - P_opensupplyreceipts,0)) 
      * Max(coalesce(j.P_CurrentStdMatlCost,0))	Planned_Order_Material_Value_Local
      , Max(coalesce(P_GrossRqmtsTotal - P_QOH - P_opensupplyreceipts,0)) 
      * Max(coalesce(j.S_POUnitPrice,0))			Planned_Order_PO_Unit_Price_Value_Local
      , Max(coalesce(P_GrossRqmtsTotal - P_QOH - P_opensupplyreceipts,0)) 
      * Max(coalesce(j.S_InvoicePrice,0))			Planned_Order_Unit_Value_Local
      

      
      
      , Max(coalesce([PartABC], 'UU'))																	PartABC
	  , Max(coalesce(PartRev, 'UU'))																	PartRev
	  , Max(coalesce(P_SafetyStock,0))																	P_SafetyStock 


      , Max(j.S_POUnitPrice)						S_POUnitPrice
      , Max(j.S_InvoicePrice)						S_InvoicePrice
      --, Max(j.S_ReceiptStdMatlCost)					S_ReceiptStdMatlCost
      , Max(j.P_CurrentStdMatlCost)					S_ReceiptStdMatlCost
      
      , Max(coalesce(partfixedleadtime, '0'))		FULL_LEAD_TIME
     
      --, Max([BuyerCode])							BuyerCode
  FROM AS_STAGE.dbo.stage_Item_Spend_Data_ManMan S
  LEFT OUTER JOIN
	(
		Select a.Org
		, a.PartNumber
		, Max(a.S_POUnitPrice)							S_POUnitPrice
		, Max(a.S_InvoicePrice)							S_InvoicePrice
		--, Max(a.S_POUnitPrice / convfactor)			S_POUnitPrice
		--, Max(a.S_InvoicePrice / convfactor)			S_InvoicePrice
		--, Max(a.S_ReceiptStdMatlCost / convfactor)	S_ReceiptStdMatlCost
		, Max(a.P_CurrentStdMatlCost * convfactor)		P_CurrentStdMatlCost
		FROM AS_STAGE.dbo.stage_Item_Spend_Data_ManMan a
		inner join
			(
			Select Org
				, PartNumber
				, MAX(S_VoucherDate) Max_Voucher_Date
			FROM AS_STAGE.dbo.stage_Item_Spend_Data_ManMan
			group by Org, PartNumber
			) b
		on a.Org = b.Org
		and a.PartNumber = b.PartNumber
		and a.S_VoucherDate = b.Max_Voucher_Date
		group by a.Org, a.PartNumber
	) j
  on s.Org = j.Org
  and s.PartNumber = j.PartNumber
  group by s.Org, s.PartNumber
GO


-- Create Combined Product Dimension
Truncate table as_dwh.dbo.Dim_Product_Combined_Invoice
Insert into as_dwh.dbo.Dim_Product_Combined_Invoice

-- Manman
Select *
	, 'N' Manman_Intercompany_Item
from AS_STAGE.dbo.Stage_ReceiptPartNum

Union All
-- Oracle
	SELECT   p.Dim_PRODUCT_KEY
             , 'Linvatec' AS Org
             , coalesce(ITEM_NUMBER, 'Undefined') 
             , coalesce(DESCRIPTION , 'Undefined') 
             , coalesce(FIXED_LEAD_TIME , '0') 
             , coalesce(ITEM_NUMBER_DESC, 'Undefined') 
             , coalesce(PLANNING_MAKE_BUY_CODE , 'UU') 
             , coalesce(PLANNER_CODE , 'Undefined') 
             
             , coalesce(actual_usage, 0) actual_usage
             , coalesce(mrp.ACTUAL_ORDER_QUANTITY, 0) ACTUAL_ORDER_QUANTITY
             , coalesce(mrp.GROSS_REQUIREMENT_QUANTITY, 0) GROSS_REQUIREMENT_QUANTITY
             , coalesce(onh.ON_HAND_QUANTITY, 0) ON_HAND_QUANTITY
             , coalesce(mrp.PLANNED_ORDER_QUANTITY, 0) PLANNED_ORDER_QUANTITY
             , coalesce(mrp.GROSS_REQUIREMENT_Material_Value_Local, 0) GROSS_REQUIREMENT_Material_Value_Local
             , coalesce(mrp.GROSS_REQUIREMENT_PO_Unit_Price_Value_Local, 0) GROSS_REQUIREMENT_PO_Unit_Price_Value_Local
             , coalesce(mrp.GROSS_REQUIREMENT_Unit_Value_Local, 0) GROSS_REQUIREMENT_Unit_Value_Local
             , coalesce(mrp.Planned_Order_Material_Value_Local, 0) Planned_Order_Material_Value_Local
             , coalesce(mrp.Planned_Order_PO_Unit_Price_Value_Local, 0) Planned_Order_PO_Unit_Price_Value_Local
             , coalesce(mrp.Planned_Order_Unit_Value_Local, 0) Planned_Order_Unit_Value_Local
             , coalesce(CYCLE_ABC_CLASS_NAME, 'UU') CYCLE_ABC_CLASS_NAME
			 , coalesce(Revision, 'UU') Revision
			 , coalesce(SAFETY_STOCK_QUANTITY, 0) SAFETY_STOCK_QUANTITY
			 , coalesce(last_PO_Unit_Price, 0) last_PO_Unit_Price
			 , coalesce(UNIT_PRICE, 0) UNIT_PRICE
			 , coalesce(Material_Cost,0) Material_Cost
			 , coalesce(FULL_LEAD_TIME , '0') FULL_LEAD_TIME
			 , 'N/A' Manman_Intercompany_Item

	FROM as_dwh.dbo.Dim_PRODUCT p
	left outer join
	(
		Select Dim_PRODUCT_KEY
				, SUM(coalesce(ACTUAL_ORDER_QUANTITY,0))						ACTUAL_ORDER_QUANTITY
				, SUM(coalesce(PLANNED_ORDER_QUANTITY,0))						PLANNED_ORDER_QUANTITY
				, SUM(coalesce(GROSS_REQUIREMENT_QUANTITY,0))					GROSS_REQUIREMENT_QUANTITY
				, SUM(coalesce(Gross_requirement_Material_Value_Local,0))		Gross_requirement_Material_Value_Local
				, SUM(coalesce(Gross_requirement_PO_Unit_Price_Value_Local,0))	Gross_requirement_PO_Unit_Price_Value_Local
				, SUM(coalesce(Gross_requirement_Unit_Value_Local,0))			Gross_requirement_Unit_Value_Local
				, SUM(coalesce(Planned_Order_Material_Value_Local,0))			Planned_Order_Material_Value_Local
				, SUM(coalesce(Planned_Order_PO_Unit_Price_Value_Local,0))		Planned_Order_PO_Unit_Price_Value_Local
				, SUM(coalesce(Planned_Order_Unit_Value_Local,0))				Planned_Order_Unit_Value_Local
		From as_dwh.dbo.Fact_MRP_PROJECTIONS_daily
		--where MRP_DATE between convert(date,getdate()) and dateadd(Year, 1,convert(date,getdate()))
		where MRP_Date >= substring(convert(varchar,dateadd(month,1,getdate()), 120),1,8)+'01' -- 1st day next month
		and   MRP_DATE < substring(convert(varchar,dateadd(month,13,getdate()), 120),1,8)+'01' -- 1st day 13 months out
		group by Dim_PRODUCT_KEY
	 ) MRP

	 on p.Dim_PRODUCT_KEY = mrp.Dim_PRODUCT_KEY
	 --where mrp.ACTUAL_ORDER_QUANTITY is not null
	 
	 left outer join
	(
		Select Dim_PRODUCT_KEY
				, Sum(coalesce(ON_HAND_QUANTITY,0))								ON_HAND_QUANTITY
				
		From as_dwh.dbo.Fact_MRP_PROJECTIONS_daily
		--where MRP_DATE between convert(date,getdate()) and dateadd(Year, 1,convert(date,getdate()))
		where MRP_Date >= substring(convert(varchar,getdate(), 120),1,8)+'01' -- 1st day This month
		and   MRP_DATE < substring(convert(varchar,dateadd(month,1,getdate()), 120),1,8)+'01' -- 1st day next months out
		group by Dim_PRODUCT_KEY
	 ) ONH

	 on p.Dim_PRODUCT_KEY = onh.Dim_PRODUCT_KEY

-- Identify Manman Intercompany products
Truncate Table as_stage.dbo.stg_Manman_Intercompany_Items
Insert Into as_stage.dbo.stg_Manman_Intercompany_Items
Select p.Org
	, p.ITEM_NUMBER
	, LU.DESCRIPTION
	, LU.LOOKUP_CODE
	, 'Y' Manman_Intercompany_Item
from as_dwh.dbo.Dim_Product_Combined_Invoice p
Left Join dw_Main.dbo.FND_LOOKUP_VALUES_VL LU
on p.Org = 
		Case 
			When LU.DESCRIPTION = 'Utica' Then 'Conasp'
			When LU.DESCRIPTION = 'Chihuahua' Then 'Mexico'
			Else ' '
		End
And p.ITEM_NUMBER = LU.LOOKUP_CODE
Where Case
		When p.Org = 'Linvatec' Then 'N/A'
		When LU.LOOKUP_CODE IS NULL Then 'N'
		Else 'Y'
	  End = 'Y'

Update as_dwh.dbo.Dim_Product_Combined_Invoice
	Set Manman_Intercompany_Item = s.Manman_Intercompany_Item
From as_dwh.dbo.Dim_Product_Combined_Invoice p
Inner Join as_stage.dbo.stg_Manman_Intercompany_Items s
on p.ITEM_NUMBER = s.LOOKUP_CODE
And p.Org = s.Org






