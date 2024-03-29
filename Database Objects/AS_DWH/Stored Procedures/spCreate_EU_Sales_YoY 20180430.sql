USE [AS_DWH]
GO
/****** Object:  StoredProcedure [Tableau].[spCreate_EU_Sales_YoY]    Script Date: 4/30/2018 8:08:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Perry Parsino
-- Create date: 2/9/2018
-- Description:	Create Tableau dataset for EU reporting
-- =============================================
ALTER PROCEDURE [Tableau].[spCreate_EU_Sales_YoY] 
AS
BEGIN

-- Create stage table from base sales data warehouse tables
Truncate Table as_stage.dbo.stg_Tableau_EU_DM
Insert 	Into as_stage.dbo.stg_Tableau_EU_DM

Select [DESCRIPTIONF] 
	, GEOGID
	, [Account_Number]
	, [Account_Name]
	, stcl.[LOCATION]  [ShipTo_Site_Name]
	, stcl.[COUNTRY_NAME] [ShipToCountryName]
	, stcl.Latitude
	, stcl.Longitude
	, stcl.[PROFILE_CLASS_NAME] 
    , stcl.[CUSTOMER_CLASS_CODE]
	, CBSIC.Division
	, CBSIC.MAJOR_DESCRIPTION
	, CBSIC.MINOR_DESCRIPTION
	, CBSIC.LINE_DESCRIPTION
	, CBSIC.GROUP_DESCRIPTION
	, p.Item_Number
	, p.[Description] Item_Description
	, itc.PRODUCT_TYPE									Capital_Disp_Inv_Item
	
	, ou.name OPERATING_UNIT
	, gc.GL_COMPANY
	, gc.GEOG1_DESCRIPTION
	, gc.GEOG2_DESCRIPTION							
	, gc.GEOG3_DESCRIPTION
	, gc.GEOG4_DESCRIPTION	
	, Coalesce(gpc.Business_Unit, 'NA')					Product_Segment_Current_BU
	, Coalesce(gpc.Product_Group, 'Unknown')			Product_Segment_Current_Product_GRP
	, Coalesce(gpc.Product_Subgroup	, 'Unknown')		Product_Segment_Current_Product_Sub_Grp
	, Coalesce(gpc.OneStream_Brand_Name, 'Unknown')		Product_Segment_Current_OS_Brand
	, Coalesce(gpc.CONCATENATED_DESCRIPTION, 'Unknown')	Product_Segment_Current_Description
	, Coalesce(gpc.Cap_Disp, 'Unknown')					Product_Segment_Current_Cap_Disp
	, gd.ActualDate										GL_Date
	, cd.ActualDate										Commissioned_Date
	, f.Dim_GL_PRODUCT_SEGMENT_CURRENT_KEY				Product_Segment_Current	
	, OHT.TRANSACTION_TYPE_NAME							Order_Type
	, ex.EXCLUSION_REASON
	, os.SOURCE_SYSTEM_NAME								SOURCE_SYSTEM_NAME
	, f.Transactional_Currency_Code
	, f.COMM_SELLING_AMOUNT_USD
	, f.COMM_SELLING_AMOUNT_Transactional
	, f.Financial_SELLING_AMOUNT_Transactional
	, f.Financial_SELLING_AMOUNT_CC
	, f.Product_Cost_Extended_USD
	, f.Product_Cost_Less_MarkUp_Extended_Functional
	, f.Corporate_ASP_Quantity								
	, f.DSR_Budget_Functional
	, f.DSR_Budget_USD
from as_dwh.edw.Fact_Sales_Order f
Inner Join [AS_DWH].edw.Dim_EXCLUSION_REASON ex
  on ex.Dim_EXCLUSION_REASON_KEY = f.Dim_EXCLUSION_REASON_KEY
  Inner Join [AS_DWH].edw.Dim_OPERATING_UNIT_V OU
  on OU.Dim_OPERATING_UNIT_KEY = f.Dim_OPERATING_UNIT_KEY
  Inner Join [AS_DWH].[EDW].[Dim_SHIP_TO_CUSTOMER_LOCATION_V] STCL
  on STCL.Dim_CUSTOMER_location_KEY = f.Dim_SHIP_TO_CUSTOMER_LOCATION_KEY
  Left Join AS_DWH.edw.Dim_GL_ACCOUNT_PRODUCT_V gpc
  on f.Dim_GL_PRODUCT_SEGMENT_CURRENT_KEY = gpc.PRODUCT
  Inner Join [AS_DWH].[dbo].Dim_SALES_GEOGRAPHY GEO
  on GEO.Dim_SALES_GEOGRAPHY_KEY = f.Dim_SALES_GEOGRAPHY_KEY
  Inner Join [AS_DWH].edw.Dim_PRODUCT_Combined_V P
  on P.Dim_PRODUCT_KEY = f.Dim_PRODUCT_KEY
  left Outer Join [AS_DWH].[dbo].TimeMaster gD
  on gd.DayID = f.Dim_GL_DATE_KEY
  Inner Join  [AS_DWH].[dbo].TimeMaster CD
  on cd.DayID = f.Dim_COMM_SALES_KEY
  Inner Join [AS_DWH].edw.Dim_ORDER_SOURCE_SYSTEM OS
  on os.Dim_ORDER_SOURCE_SYSTEM_KEY = f.Dim_ORDER_SOURCE_SYSTEM_KEY
  Inner Join [AS_DWH].[dbo].Dim_ORDER_TYPE OHT
  on oht.Dim_ORDER_TYPE_KEY = f.Dim_ORDER_HEADER_TYPE_KEY
  Inner Join [AS_DWH].[dbo].[DIM_LINVATEC_ITEM_TYPE_CATEGORY] litc
  on litc.DIM_LINVATEC_ITEM_TYPE_CATEGORY_KEY = P.DIM_LINVATEC_ITEM_TYPE_CATEGORY_KEY
  Inner Join AS_DWH.dbo.Dim_INVENTORY_ITEM_CATEGORY itc
  on itc.Dim_INVENTORY_ITEM_CATEGORY_KEY = p.Dim_INVENTORY_ITEM_CATEGORY_KEY
  Inner Join as_dwh.dbo.Dim_CONMED_ITEM_CATEGORY CBSIC
  on p.DIM_CONMED_ITEM_CATEGORY_KEY = cbsic.Dim_CONMED_ITEM_CATEGORY_KEY
  Inner Join AS_DWH.EDW.Dim_GL_COMPANY_Hierarchy gc
  on f.Dim_GL_Company_Hierarchy_KEY = gc.Dim_GL_Company_Hierarchy_KEY
 Where (Geog1_description = 'International'
 --(GEOG2_DESCRIPTION = 'Europe' Or GEOG3_DESCRIPTION = 'Latin America'
		Or gpc.Business_Unit = 'Endoscopic Technologies')
And Year(gd.ActualDate) in (Year(Getdate())-2 , Year(Getdate())-1 , Year(Getdate()))
And OHT.TRANSACTION_TYPE_NAME not like 'HOUSE EVAL%' and  OHT.TRANSACTION_TYPE_NAME not like 'ADVANTAGE%'
And Not (Financial_SELLING_AMOUNT_Transactional = 0 and Coalesce(f.DSR_Budget_USD,0) = 0 
		and Corporate_ASP_Quantity = 0 And Product_Cost_Less_MarkUp_Extended_Functional = 0
		and COMM_SELLING_AMOUNT_Transactional = 0)
--And gd.ActualDate <= Getdate()
-- Exclude future amoritized contract sales
ANd Not (Year(gd.ActualDate) = Year(Getdate()) And Month(gd.ActualDate) > Month(Getdate()) 
		 And Exclusion_Reason = 'L. Service Contract Revenue')
-- Exclude current and previous month MTF journal entries. Bringing in transactions in second YOY insert
ANd Not (((Year(gd.ActualDate) = Year(Getdate()) And Month(gd.ActualDate) = Month(Getdate())) Or
		 (Year(gd.ActualDate) = Year(Dateadd(Month, -1,Getdate())) 
					And Month(gd.ActualDate) = Month(Dateadd(Month, -1,Getdate()))))
		 And Exclusion_Reason = 'O. GL Journal Entry MTF')
End

Begin
-- Insert Main rows into YOY dataset
Truncate Table as_dwh.Tableau.EU_Sales_YoY
Insert Into as_dwh.Tableau.EU_Sales_YoY
([Sales_Rep] ,GEOGID, [Account_Number] ,[Account_Name] ,[Division] ,[MAJOR_DESCRIPTION] 
		,[MINOR_DESCRIPTION]
		, [LINE_DESCRIPTION] ,[GROUP_DESCRIPTION] ,[Item_Number] ,[Item_Description] ,[Capital_Disp_Inv_Item]
		, [ShipTo_Site_Name] ,[ShipToCountryName] ,[OPERATING_UNIT] ,[GEOG2_DESCRIPTION] ,[GEOG3_DESCRIPTION]
		, [GEOG4_DESCRIPTION] ,[GL_Company] ,[Product_Segment_Current_BU] ,[Product_Segment_Current_Product_GRP]
		, [Product_Segment_Current_Product_Sub_GRP] ,[Product_Segment_Current_OS_Brand]
		, [Product_Segment_Current_Description] ,[Latitude] ,[Longitude] ,[Sales_Month]
		, [Sales_Year] ,[Sales_Date] ,[TRANSACTIONAL_CURRENCY_CODE] ,[Corporate_Rate] ,[Budgeted_Rate]
		, [Current_Budgeted_Rate] ,[Sales] ,[Prior_Year_Sales] ,[Prior2_Year_Sales] ,[Current_Year_Sales]
		, [Corporate_ASP_Quantity] ,[Prior_Year_Quantity] ,[Prior2_Year_Quantity] ,[Current_Year_Quantity]
		, [Product_Cost] ,[Prior_Year_Cost] ,[Prior2_Year_Cost] ,[Current_Year_Cost] ,[Current_YTD_Sales]
		, [Prior_YTD_Sales],[Prior2_YTD_Sales] ,[Current_QTD_Sales] ,[Prior_QTD_Sales] ,[Prior2_QTD_Sales]
		, [Current_MTD_Sales] ,[Prior_MTD_Sales] ,[Prior2_MTD_Sales] ,[Current_YTD_Cost] ,[Prior_YTD_Cost]
		, [Prior2_YTD_Cost] ,[Current_QTD_Cost] ,[Prior_QTD_Cost] ,[Prior2_QTD_Cost]  ,[Current_MTD_Cost]
		, [Prior_MTD_Cost],[Prior2_MTD_Cost],[Current_YTD_Quantity] ,[Prior_YTD_Quantity] ,[Prior2_YTD_Quantity]
		, [Current_QTD_Quantity] ,[Prior_QTD_Quantity] ,[Prior2_QTD_Quantity] ,[Current_MTD_Quantity]
		, [Prior_MTD_Quantity] ,[Prior2_MTD_Quantity] 
		, Sales_USD, Prior_Year_Sales_USD, Prior2_Year_Sales_USD
		, Current_Year_Sales_USD, Current_YTD_Sales_USD, Prior_YTD_Sales_USD
		, Prior2_YTD_Sales_USD, Current_QTD_Sales_USD,Prior_QTD_Sales_USD
		, Prior2_QTD_Sales_USD, Current_MTD_Sales_USD, Prior_MTD_Sales_USD
		, Prior2_MTD_Sales_USD
	  
		, Product_Cost_USD, Prior_Year_Cost_USD, Prior2_Year_Cost_USD
		, Current_Year_Cost_USD, Current_YTD_Cost_USD, Prior_YTD_Cost_USD
		, Prior2_YTD_Cost_USD, Current_QTD_Cost_USD,Prior_QTD_Cost_USD
		, Prior2_QTD_Cost_USD, Current_MTD_Cost_USD, Prior_MTD_Cost_USD
		, Prior2_MTD_Cost_USD

		,[DSR_Budget_Functional] ,[DSR_Budget_USD]
		,[Exclusion_Reason] ,[Product_Segment_Current] 
		,[Forecast] ,[Forecast_USD]
		,[PROFILE_CLASS_NAME]
		,[CUSTOMER_CLASS_CODE], GS_Ortho, Last_Update_Date, LC_Quota)

Select [DESCRIPTIONF] Sales_Rep
	, GEOGID
	, [Account_Number]
	, [Account_Name]
	, Division
	, MAJOR_DESCRIPTION
	, MINOR_DESCRIPTION
	, LINE_DESCRIPTION
	, GROUP_DESCRIPTION
	, Item_Number
	, Item_Description
	, [Capital_Disp_Inv_Item]
	, [ShipTo_Site_Name]
	, [ShipToCountryName]
	, OPERATING_UNIT
	, GEOG2_DESCRIPTION
	, GEOG3_DESCRIPTION
	, GEOG4_DESCRIPTION
	, GL_Company
	, Product_Segment_Current_BU
	, Product_Segment_Current_Product_GRP
	, Product_Segment_Current_Product_Sub_GRP
	, Product_Segment_Current_OS_Brand
	, Product_Segment_Current_Description
	, Latitude
	, Longitude
	, Month(GL_Date) Sales_Month
	, Year(GL_Date) Sales_Year
	, GL_Date		Sales_Date
	, m.TRANSACTIONAL_CURRENCY_CODE
	, Max(Coalesce(cr.Conversion_Rate,1)) Corporate_Rate 
	, Max(Coalesce(br.Conversion_Rate,1)) Budgeted_Rate 
	, Max(Coalesce(cbr.Conversion_Rate,1)) Current_Budgeted_Rate
	, Sum(m.Financial_SELLING_AMOUNT_Transactional) Sales
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())-1 
			Then m.Financial_SELLING_AMOUNT_Transactional
			Else 0 End) Prior_Year_Sales
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())-2 
			Then m.Financial_SELLING_AMOUNT_Transactional
			Else 0 End) Prior2_Year_Sales
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate()) 
			Then m.Financial_SELLING_AMOUNT_Transactional
			Else 0 End) Current_Year_Sales
	, Sum([Corporate_ASP_Quantity]) [Corporate_ASP_Quantity]
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())-1 
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior_Year_Quantity
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())-2
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior2_Year_Quantity
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate()) 
			Then [Corporate_ASP_Quantity]
			Else 0 End) Current_Year_Quantity
	, Sum(m.Product_Cost_Less_MarkUp_Extended_Functional) Product_Cost
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())-1 
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior_Year_Cost
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())-2 
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior2_Year_Cost
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate()) 
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Current_Year_Cost
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())
			Then m.Financial_SELLING_AMOUNT_Transactional
			Else 0 End) Current_YTD_Sales
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.YearFirstDate)
			 And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Financial_SELLING_AMOUNT_Transactional
			Else 0 End) Prior_YTD_Sales
	, Sum(
		Case 
		When GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Financial_SELLING_AMOUNT_Transactional
			Else 0 End) Prior2_YTD_Sales
	, Sum(
		Case 
		When GL_Date >= t.QuarterFirstDate And Year(GL_Date) = Year(Getdate()) 
			Then m.Financial_SELLING_AMOUNT_Transactional
			Else 0 End) Current_QTD_Sales
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.QuarterFirstDate)
			And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Financial_SELLING_AMOUNT_Transactional
			Else 0 End) Prior_QTD_Sales
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -2,t.QuarterFirstDate)
			And GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Financial_SELLING_AMOUNT_Transactional
			Else 0 End) Prior2_QTD_Sales
	, Sum(
		Case 
		When GL_Date >= t.MonthFirstDate And Year(GL_Date) = Year(Getdate()) 
			Then m.Financial_SELLING_AMOUNT_Transactional
			Else 0 End) Current_MTD_Sales
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.MonthFirstDate)
			And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Financial_SELLING_AMOUNT_Transactional
			Else 0 End) Prior_MTD_Sales
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -2,t.MonthFirstDate)
			And GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Financial_SELLING_AMOUNT_Transactional
			Else 0 End) Prior2_MTD_Sales
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Current_YTD_Cost
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.YearFirstDate)
			 And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior_YTD_Cost
	, Sum(
		Case 
		When GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			And GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior2_YTD_Cost
	, Sum(
		Case 
		When GL_Date >= t.QuarterFirstDate And Year(GL_Date) = Year(Getdate()) 
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Current_QTD_Cost
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.QuarterFirstDate)
			And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior_QTD_Cost
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -2,t.QuarterFirstDate)
			And GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior2_QTD_Cost
	, Sum(
		Case 
		When GL_Date >= t.MonthFirstDate And Year(GL_Date) = Year(Getdate()) 
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Current_MTD_Cost
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.MonthFirstDate)
			And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior_MTD_Cost
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -2,t.MonthFirstDate)
			And GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior2_MTD_Cost
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())
			Then [Corporate_ASP_Quantity]
			Else 0 End) Current_YTD_Quantity
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.YearFirstDate)
			 And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior_YTD_Quantity
	, Sum(
		Case 
		When GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			And GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior2_YTD_Quantity
	, Sum(
		Case 
		When GL_Date >= t.QuarterFirstDate And Year(GL_Date) = Year(Getdate()) 
			Then [Corporate_ASP_Quantity]
			Else 0 End) Current_QTD_Quantity
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.QuarterFirstDate)
			And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior_QTD_Quantity
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -2,t.QuarterFirstDate)
			And GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior2_QTD_Quantity
	, Sum(
		Case 
		When GL_Date >= t.MonthFirstDate And Year(GL_Date) = Year(Getdate()) 
			Then [Corporate_ASP_Quantity]
			Else 0 End) Current_MTD_Quantity
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.MonthFirstDate)
			And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior_MTD_Quantity
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -2,t.MonthFirstDate)
			And GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior2_MTD_Quantity

	, Sum(m.Financial_SELLING_AMOUNT_CC) Sales
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())-1 
			Then m.Financial_SELLING_AMOUNT_CC
			Else 0 End) Prior_Year_Sales
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())-2 
			Then m.Financial_SELLING_AMOUNT_CC
			Else 0 End) Prior2_Year_Sales
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate()) 
			Then m.Financial_SELLING_AMOUNT_CC
			Else 0 End) Current_Year_Sales
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())
			Then m.Financial_SELLING_AMOUNT_CC
			Else 0 End) Current_YTD_Sales
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.YearFirstDate)
			 And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Financial_SELLING_AMOUNT_CC
			Else 0 End) Prior_YTD_Sales
	, Sum(
		Case 
		When GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Financial_SELLING_AMOUNT_CC
			Else 0 End) Prior2_YTD_Sales
	, Sum(
		Case 
		When GL_Date >= t.QuarterFirstDate And Year(GL_Date) = Year(Getdate()) 
			Then m.Financial_SELLING_AMOUNT_CC
			Else 0 End) Current_QTD_Sales
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.QuarterFirstDate)
			And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Financial_SELLING_AMOUNT_CC
			Else 0 End) Prior_QTD_Sales
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -2,t.QuarterFirstDate)
			And GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Financial_SELLING_AMOUNT_CC
			Else 0 End) Prior2_QTD_Sales
	, Sum(
		Case 
		When GL_Date >= t.MonthFirstDate And Year(GL_Date) = Year(Getdate()) 
			Then m.Financial_SELLING_AMOUNT_CC
			Else 0 End) Current_MTD_Sales
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.MonthFirstDate)
			And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Financial_SELLING_AMOUNT_CC
			Else 0 End) Prior_MTD_Sales
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -2,t.MonthFirstDate)
			And GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Financial_SELLING_AMOUNT_CC
			Else 0 End) Prior2_MTD_Sales
	
	, Sum(m.Product_Cost_Extended_USD) Product_Cost
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())-1 
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior_Year_Cost
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())-2 
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior2_Year_Cost
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate()) 
			Then m.Product_Cost_Extended_USD
			Else 0 End) Current_Year_Cost
	, Sum(
		Case 
		When Year(GL_Date) = Year(Getdate())
			Then m.Product_Cost_Extended_USD
			Else 0 End) Current_YTD_Cost
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.YearFirstDate)
			 And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior_YTD_Cost
	, Sum(
		Case 
		When GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			And GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior2_YTD_Cost
	, Sum(
		Case 
		When GL_Date >= t.QuarterFirstDate And Year(GL_Date) = Year(Getdate()) 
			Then m.Product_Cost_Extended_USD
			Else 0 End) Current_QTD_Cost
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.QuarterFirstDate)
			And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior_QTD_Cost
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -2,t.QuarterFirstDate)
			And GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior2_QTD_Cost
	, Sum(
		Case 
		When GL_Date >= t.MonthFirstDate And Year(GL_Date) = Year(Getdate()) 
			Then m.Product_Cost_Extended_USD
			Else 0 End) Current_MTD_Cost
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -1,t.MonthFirstDate)
			And GL_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior_MTD_Cost
	, Sum(
		Case 
		When GL_Date >= DateAdd(Year, -2,t.MonthFirstDate)
			And GL_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior2_MTD_Cost

	, Sum(Coalesce(DSR_Budget_Functional,0)) DSR_Budget_Functional
	, Sum(Coalesce(DSR_Budget_USD,0)) DSR_Budget_USD
	, m.EXCLUSION_REASON
	, m.Product_Segment_Current
	, 0
	, 0
	, Max([PROFILE_CLASS_NAME]) [PROFILE_CLASS_NAME] 
    , Max([CUSTOMER_CLASS_CODE]) [CUSTOMER_CLASS_CODE]
	, CASE	
			WHEN LEFT(Coalesce(Product_Segment_Current_Description, 'Unknown'),1) = '1' THEN 'Ortho'
			WHEN LEFT(Coalesce(Product_Segment_Current_Description, 'Unknown'),1) = '5' THEN 'GS'
			ELSE 'Other'
	  END
	, getdate() Last_Update_Date
	, 0 LC_Quota
From as_stage.dbo.stg_Tableau_EU_DM m
Inner join as_dwh.dbo.timemaster t
on t.actualdate = cast(getdate() as date)
Left Join 
    (
	select from_currency_code, to_currency_code, period_name, Max(Conversion_Rate) Conversion_Rate
	from as_dwh.dbo.Dim_CURRENCY_CONVERSION
	group by from_currency_code, to_currency_code, period_name
  ) cr
  on cr.from_currency_code = m.Transactional_Currency_Code
  and cr.to_currency_code = 'USD'
  and cr.period_name =  upper(replace(right(convert(varchar(9),m.GL_Date,6),6),' ','-'))

Left Join
	(select datepart(YYYY ,conversion_date ) AS COST_YEAR 
			, TO_CURRENCY
			, MAX(conversion_rate) AS CONVERSION_RATE 
	from dw_main.dbo.gl_daily_rates
	where CONVERSION_TYPE in ( '1002') 
	and FROM_CURRENCY = 'USD'
	group by  TO_CURRENCY, datepart(YYYY ,conversion_date )
	) br
  On br.COST_YEAR = YEAR(m.GL_Date)
  And br.TO_CURRENCY = m.Transactional_Currency_Code

  Left Join
	(select datepart(YYYY ,conversion_date ) AS COST_YEAR 
			, TO_CURRENCY
			, MAX(conversion_rate) AS CONVERSION_RATE 
	from dw_main.dbo.gl_daily_rates
	where CONVERSION_TYPE in ( '1002') 
	and FROM_CURRENCY = 'USD'
	group by  TO_CURRENCY, datepart(YYYY ,conversion_date )
	) cbr
  On cbr.COST_YEAR = YEAR(Getdate())
  And cbr.TO_CURRENCY = m.Transactional_Currency_Code
--Where OPERATING_UNIT = 'LNV_SE_OU_01'
Where (Geog1_description = 'International'
--(GEOG2_DESCRIPTION = 'Europe' Or GEOG3_DESCRIPTION = 'Latin America'
	Or Product_Segment_Current_BU = 'Endoscopic Technologies')
And Year(GL_Date) in (Year(Getdate())-2 , Year(Getdate())-1 , Year(Getdate()))
And Order_Type not like 'HOUSE EVAL%' and  Order_Type not like 'ADVANTAGE%'
And Not (m.Financial_SELLING_AMOUNT_Transactional = 0 and Coalesce(DSR_Budget_USD,0) = 0 
		and m.Corporate_ASP_Quantity = 0 And m.Product_Cost_Less_MarkUp_Extended_Functional = 0)
--And GL_Date <= Getdate()
-- Exclude future amoritized contract sales
ANd Not (Year(GL_Date) = Year(Getdate()) And Month(GL_Date) > Month(Getdate()) 
		 And Exclusion_Reason = 'L. Service Contract Revenue')
-- Exclude current and previous month MTF journal entries. Bringing in transactions in next insert
ANd Not (((Year(GL_Date) = Year(Getdate()) And Month(GL_Date) = Month(Getdate())) Or
		 (Year(GL_Date) = Year(Dateadd(Month, -1,Getdate())) 
					And Month(GL_Date) = Month(Dateadd(Month, -1,Getdate()))))
		 And Exclusion_Reason = 'O. GL Journal Entry MTF')
Group by [DESCRIPTIONF] 
	, GEOGID
	, [Account_Number]
	, [Account_Name]
	, Division
	, MAJOR_DESCRIPTION
	, MINOR_DESCRIPTION
	, LINE_DESCRIPTION
	, GROUP_DESCRIPTION
	, Item_Number
	, Item_Description
	, [Capital_Disp_Inv_Item]
	, [ShipTo_Site_Name]
	, [ShipToCountryName]
	, OPERATING_UNIT
	, GEOG2_DESCRIPTION
	, GEOG3_DESCRIPTION
	, GEOG4_DESCRIPTION
	, GL_Company
	, Product_Segment_Current_BU
	, Product_Segment_Current_Product_GRP
	, Product_Segment_Current_Product_Sub_GRP
	, Product_Segment_Current_OS_Brand
	, Product_Segment_Current_Description
	, Latitude
	, Longitude
	, GL_Date
	, Year(GL_Date)
	, Month(GL_Date)
	, m.TRANSACTIONAL_CURRENCY_CODE
	, m.EXCLUSION_REASON
	, m.Product_Segment_Current
	, CASE	
			WHEN LEFT(Coalesce(Product_Segment_Current_Description, 'Unknown'),1) = '1' THEN 'Ortho'
			WHEN LEFT(Coalesce(Product_Segment_Current_Description, 'Unknown'),1) = '5' THEN 'GS'
			ELSE 'Other'
	  END

Union All

-- Add Current Month and previous month MTF Commissioned Sales
Select [DESCRIPTIONF] Sales_Rep
	, GEOGID
	, [Account_Number]
	, [Account_Name]
	, Division
	, MAJOR_DESCRIPTION
	, MINOR_DESCRIPTION
	, LINE_DESCRIPTION
	, GROUP_DESCRIPTION
	, Item_Number
	, Item_Description
	, [Capital_Disp_Inv_Item]
	, [ShipTo_Site_Name]
	, [ShipToCountryName]
	, OPERATING_UNIT
	, GEOG2_DESCRIPTION
	, GEOG3_DESCRIPTION
	, GEOG4_DESCRIPTION
	, GL_Company
	, Product_Segment_Current_BU
	, Product_Segment_Current_Product_GRP
	, Product_Segment_Current_Product_Sub_GRP
	, Product_Segment_Current_OS_Brand
	, Product_Segment_Current_Description
	, Latitude
	, Longitude
	, Month(Commissioned_Date) Sales_Month
	, Year(Commissioned_Date) Sales_Year
	, Commissioned_Date		Sales_Date
	, m.TRANSACTIONAL_CURRENCY_CODE
	, Max(Coalesce(cr.Conversion_Rate,1)) Corporate_Rate 
	, Max(Coalesce(br.Conversion_Rate,1)) Budgeted_Rate 
	, Max(Coalesce(cbr.Conversion_Rate,1)) Current_Budgeted_Rate
	, Sum(m.COMM_SELLING_AMOUNT_Transactional / 2) Sales
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())-1 
			Then m.COMM_SELLING_AMOUNT_Transactional / 2
			Else 0 End) Prior_Year_Sales
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())-2 
			Then m.COMM_SELLING_AMOUNT_Transactional / 2
			Else 0 End) Prior2_Year_Sales
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate()) 
			Then m.COMM_SELLING_AMOUNT_Transactional / 2
			Else 0 End) Current_Year_Sales
	, Sum([Corporate_ASP_Quantity]) [Quantity_Invoiced]
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())-1 
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior_Year_Quantity
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())-2
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior2_Year_Quantity
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate()) 
			Then [Corporate_ASP_Quantity]
			Else 0 End) Current_Year_Quantity
	, Sum(m.Product_Cost_Less_MarkUp_Extended_Functional) Product_Cost
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())-1 
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior_Year_Cost
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())-2 
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior2_Year_Cost
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate()) 
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Current_Year_Cost
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())
			Then m.COMM_SELLING_AMOUNT_Transactional / 2
			Else 0 End) Current_YTD_Sales
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.YearFirstDate)
			 And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.COMM_SELLING_AMOUNT_Transactional / 2
			Else 0 End) Prior_YTD_Sales
	, Sum(
		Case 
		When Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.COMM_SELLING_AMOUNT_Transactional / 2
			Else 0 End) Prior2_YTD_Sales
	, Sum(
		Case 
		When Commissioned_Date >= t.QuarterFirstDate And Year(Commissioned_Date) = Year(Getdate()) 
			Then m.COMM_SELLING_AMOUNT_Transactional / 2
			Else 0 End) Current_QTD_Sales
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.QuarterFirstDate)
			And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.COMM_SELLING_AMOUNT_Transactional / 2
			Else 0 End) Prior_QTD_Sales
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -2,t.QuarterFirstDate)
			And Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.COMM_SELLING_AMOUNT_Transactional / 2
			Else 0 End) Prior2_QTD_Sales
	, Sum(
		Case 
		When Commissioned_Date >= t.MonthFirstDate And Year(Commissioned_Date) = Year(Getdate()) 
			Then m.COMM_SELLING_AMOUNT_Transactional / 2
			Else 0 End) Current_MTD_Sales
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.MonthFirstDate)
			And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.COMM_SELLING_AMOUNT_Transactional / 2
			Else 0 End) Prior_MTD_Sales
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -2,t.MonthFirstDate)
			And Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.COMM_SELLING_AMOUNT_Transactional / 2
			Else 0 End) Prior2_MTD_Sales
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Current_YTD_Cost
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.YearFirstDate)
			 And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior_YTD_Cost
	, Sum(
		Case 
		When Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			And Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior2_YTD_Cost
	, Sum(
		Case 
		When Commissioned_Date >= t.QuarterFirstDate And Year(Commissioned_Date) = Year(Getdate()) 
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Current_QTD_Cost
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.QuarterFirstDate)
			And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior_QTD_Cost
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -2,t.QuarterFirstDate)
			And Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior2_QTD_Cost
	, Sum(
		Case 
		When Commissioned_Date >= t.MonthFirstDate And Year(Commissioned_Date) = Year(Getdate()) 
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Current_MTD_Cost
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.MonthFirstDate)
			And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior_MTD_Cost
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -2,t.MonthFirstDate)
			And Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Less_MarkUp_Extended_Functional
			Else 0 End) Prior2_MTD_Cost
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())
			Then [Corporate_ASP_Quantity]
			Else 0 End) Current_YTD_Quantity
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.YearFirstDate)
			 And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior_YTD_Quantity
	, Sum(
		Case 
		When Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			And Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior2_YTD_Quantity
	, Sum(
		Case 
		When Commissioned_Date >= t.QuarterFirstDate And Year(Commissioned_Date) = Year(Getdate()) 
			Then [Corporate_ASP_Quantity]
			Else 0 End) Current_QTD_Quantity
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.QuarterFirstDate)
			And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior_QTD_Quantity
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -2,t.QuarterFirstDate)
			And Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior2_QTD_Quantity
	, Sum(
		Case 
		When Commissioned_Date >= t.MonthFirstDate And Year(Commissioned_Date) = Year(Getdate()) 
			Then [Corporate_ASP_Quantity]
			Else 0 End) Current_MTD_Quantity
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.MonthFirstDate)
			And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior_MTD_Quantity
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -2,t.MonthFirstDate)
			And Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then [Corporate_ASP_Quantity]
			Else 0 End) Prior2_MTD_Quantity

	, Sum(m.COMM_SELLING_AMOUNT_USD / 2) Sales
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())-1 
			Then m.COMM_SELLING_AMOUNT_USD / 2
			Else 0 End) Prior_Year_Sales
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())-2 
			Then m.COMM_SELLING_AMOUNT_USD / 2
			Else 0 End) Prior2_Year_Sales
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate()) 
			Then m.COMM_SELLING_AMOUNT_USD / 2
			Else 0 End) Current_Year_Sales
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())
			Then m.COMM_SELLING_AMOUNT_USD / 2
			Else 0 End) Current_YTD_Sales
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.YearFirstDate)
			 And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.COMM_SELLING_AMOUNT_USD / 2
			Else 0 End) Prior_YTD_Sales
	, Sum(
		Case 
		When Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.COMM_SELLING_AMOUNT_USD / 2
			Else 0 End) Prior2_YTD_Sales
	, Sum(
		Case 
		When Commissioned_Date >= t.QuarterFirstDate And Year(Commissioned_Date) = Year(Getdate()) 
			Then m.COMM_SELLING_AMOUNT_USD / 2
			Else 0 End) Current_QTD_Sales
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.QuarterFirstDate)
			And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.COMM_SELLING_AMOUNT_USD / 2
			Else 0 End) Prior_QTD_Sales
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -2,t.QuarterFirstDate)
			And Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.COMM_SELLING_AMOUNT_USD / 2
			Else 0 End) Prior2_QTD_Sales
	, Sum(
		Case 
		When Commissioned_Date >= t.MonthFirstDate And Year(Commissioned_Date) = Year(Getdate()) 
			Then m.COMM_SELLING_AMOUNT_USD / 2
			Else 0 End) Current_MTD_Sales
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.MonthFirstDate)
			And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.COMM_SELLING_AMOUNT_USD / 2
			Else 0 End) Prior_MTD_Sales
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -2,t.MonthFirstDate)
			And Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.COMM_SELLING_AMOUNT_USD / 2
			Else 0 End) Prior2_MTD_Sales
	
	, Sum(m.Product_Cost_Extended_USD) Product_Cost
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())-1 
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior_Year_Cost
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())-2 
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior2_Year_Cost
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate()) 
			Then m.Product_Cost_Extended_USD
			Else 0 End) Current_Year_Cost
	, Sum(
		Case 
		When Year(Commissioned_Date) = Year(Getdate())
			Then m.Product_Cost_Extended_USD
			Else 0 End) Current_YTD_Cost
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.YearFirstDate)
			 And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior_YTD_Cost
	, Sum(
		Case 
		When Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			And Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior2_YTD_Cost
	, Sum(
		Case 
		When Commissioned_Date >= t.QuarterFirstDate And Year(Commissioned_Date) = Year(Getdate()) 
			Then m.Product_Cost_Extended_USD
			Else 0 End) Current_QTD_Cost
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.QuarterFirstDate)
			And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior_QTD_Cost
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -2,t.QuarterFirstDate)
			And Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior2_QTD_Cost
	, Sum(
		Case 
		When Commissioned_Date >= t.MonthFirstDate And Year(Commissioned_Date) = Year(Getdate()) 
			Then m.Product_Cost_Extended_USD
			Else 0 End) Current_MTD_Cost
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -1,t.MonthFirstDate)
			And Commissioned_Date <= DateAdd(Year, -1,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior_MTD_Cost
	, Sum(
		Case 
		When Commissioned_Date >= DateAdd(Year, -2,t.MonthFirstDate)
			And Commissioned_Date <= DateAdd(Year, -2,DateAdd(Day, -1,Getdate()))
			Then m.Product_Cost_Extended_USD
			Else 0 End) Prior2_MTD_Cost

	--, Sum(Coalesce(DSR_Budget_Functional,0)) DSR_Budget_Functional
	--, Sum(Coalesce(DSR_Budget_USD,0)) DSR_Budget_USD
	, 0 DSR_Budget_Functional
	, 0 DSR_Budget_USD
	, m.EXCLUSION_REASON
	, m.Product_Segment_Current
	, 0
	, 0
	, Max([PROFILE_CLASS_NAME]) [PROFILE_CLASS_NAME] 
    , Max([CUSTOMER_CLASS_CODE]) [CUSTOMER_CLASS_CODE]
	, CASE	
			WHEN LEFT(Coalesce(Product_Segment_Current_Description, 'Unknown'),1) = '1' THEN 'Ortho'
			WHEN LEFT(Coalesce(Product_Segment_Current_Description, 'Unknown'),1) = '5' THEN 'GS'
			ELSE 'Other'
	  END
	, getdate() Last_Update_Date
	, 0 LC_Quota
From as_stage.dbo.stg_Tableau_EU_DM m
Inner join as_dwh.dbo.timemaster t
on t.actualdate = cast(getdate() as date)
Left Join 
    (
	select from_currency_code, to_currency_code, period_name, Max(Conversion_Rate) Conversion_Rate
	from as_dwh.dbo.Dim_CURRENCY_CONVERSION
	group by from_currency_code, to_currency_code, period_name
  ) cr
  on cr.from_currency_code = m.Transactional_Currency_Code
  and cr.to_currency_code = 'USD'
  and cr.period_name =  upper(replace(right(convert(varchar(9),m.Commissioned_Date,6),6),' ','-'))

Left Join
	(select datepart(YYYY ,conversion_date ) AS COST_YEAR 
			, TO_CURRENCY
			, MAX(conversion_rate) AS CONVERSION_RATE 
	from dw_main.dbo.gl_daily_rates
	where CONVERSION_TYPE in ( '1002') 
	and FROM_CURRENCY = 'USD'
	group by  TO_CURRENCY, datepart(YYYY ,conversion_date )
	) br
  On br.COST_YEAR = YEAR(m.Commissioned_Date)
  And br.TO_CURRENCY = m.Transactional_Currency_Code

  Left Join
	(select datepart(YYYY ,conversion_date ) AS COST_YEAR 
			, TO_CURRENCY
			, MAX(conversion_rate) AS CONVERSION_RATE 
	from dw_main.dbo.gl_daily_rates
	where CONVERSION_TYPE in ( '1002') 
	and FROM_CURRENCY = 'USD'
	group by  TO_CURRENCY, datepart(YYYY ,conversion_date )
	) cbr
  On cbr.COST_YEAR = YEAR(Getdate())
  And cbr.TO_CURRENCY = m.Transactional_Currency_Code
--Where OPERATING_UNIT = 'LNV_SE_OU_01'
Where (Geog1_description = 'International'
--(GEOG2_DESCRIPTION = 'Europe' Or GEOG3_DESCRIPTION = 'Latin America'
		Or Product_Segment_Current_BU = 'Endoscopic Technologies')
And Order_Type not like 'HOUSE EVAL%' and  Order_Type not like 'ADVANTAGE%'
And Not (m.COMM_SELLING_AMOUNT_USD = 0 and Coalesce(DSR_Budget_USD,0) = 0 
		and m.Corporate_ASP_Quantity = 0 And m.Product_Cost_Less_MarkUp_Extended_Functional = 0)
--ANd Year(Commissioned_Date) = 2017 And Month(Commissioned_Date) = 12
-- Include only current and previous month MTF commissioned sales
ANd ((Year(Commissioned_Date) = Year(Getdate()) And Month(Commissioned_Date) = Month(Getdate())) Or
		 (Year(Commissioned_Date) = Year(Dateadd(Month, -1,Getdate())) 
					And Month(Commissioned_Date) = Month(Dateadd(Month, -1,Getdate()))))
And SOURCE_SYSTEM_NAME = 'MTF Sales'
Group by [DESCRIPTIONF] 
	, GEOGID
	, [Account_Number]
	, [Account_Name]
	, Division
	, MAJOR_DESCRIPTION
	, MINOR_DESCRIPTION
	, LINE_DESCRIPTION
	, GROUP_DESCRIPTION
	, Item_Number
	, Item_Description
	, [Capital_Disp_Inv_Item]
	, [ShipTo_Site_Name]
	, [ShipToCountryName]
	, OPERATING_UNIT
	, GEOG2_DESCRIPTION
	, GEOG3_DESCRIPTION
	, GEOG4_DESCRIPTION
	, GL_Company
	, Product_Segment_Current_BU
	, Product_Segment_Current_Product_GRP
	, Product_Segment_Current_Product_Sub_GRP
	, Product_Segment_Current_OS_Brand
	, Product_Segment_Current_Description
	, Latitude
	, Longitude
	, Commissioned_Date
	, Year(Commissioned_Date)
	, Month(Commissioned_Date)
	, m.TRANSACTIONAL_CURRENCY_CODE
	, m.EXCLUSION_REASON
	, m.Product_Segment_Current
	, CASE	
			WHEN LEFT(Coalesce(Product_Segment_Current_Description, 'Unknown'),1) = '1' THEN 'Ortho'
			WHEN LEFT(Coalesce(Product_Segment_Current_Description, 'Unknown'),1) = '5' THEN 'GS'
			ELSE 'Other'
	  END

-- Add Forecast
Insert Into as_dwh.Tableau.EU_Sales_YoY

SELECT 'Unknown' [Sales_Rep]
	  , 'Unknown' GEOGID
      , 'Unknown' [Account_Number]
      , 'Unknown' [Account_Name]
      , 'Unknown' [Division]
      , 'Unknown' [MAJOR_DESCRIPTION]
      , 'Unknown' [MINOR_DESCRIPTION]
      , 'Unknown' [LINE_DESCRIPTION]
      , 'Unknown' [GROUP_DESCRIPTION]
      , 'Unknown' [Item_Number]
      , 'Unknown' [Item_Description]
      , 'Unknown' [Capital_Disp_Inv_Item]
      , 'Unknown' [ShipTo_Site_Name]
      , 'Unknown' [ShipToCountryName]
      , Coalesce(c.OPERATING_UNIT, 
				Case 
					When f.[GL_Company] = '60' Then			'LNV_GB_OU_01'
					When f.[GL_Company] Like '[a-z]%' Then	'LNV_US_OU_01'
					Else 'Unknown' End )		[OPERATING_UNIT]
      , Coalesce(d.[GEOG2_DESCRIPTION], 'Unknown') [GEOG2_DESCRIPTION]
	  , Coalesce(d.[GEOG3_DESCRIPTION], 'Unknown') [GEOG3_DESCRIPTION]
      , Coalesce(d.[GEOG4_DESCRIPTION], 'Unknown') [GEOG4_DESCRIPTION]
      , f.[GL_Company]
      , Coalesce(p.Business_Unit, 'Unknown')			[Product_Segment_Current_BU]
      , Coalesce(p.Product_Group, 'Unknown')			[Product_Segment_Current_Product_GRP]
      , Coalesce(p.Product_Subgroup, 'Unknown')			[Product_Segment_Current_Product_Sub_GRP]
      , Coalesce(p.OneStream_Brand_Name, 'Unknown')		[Product_Segment_Current_OS_Brand]
      , Coalesce(p.CONCATENATED_DESCRIPTION, 'Unknown')	[Product_Segment_Current_Description]
      , 0 [Latitude]
      , 0 [Longitude]
      , Forecast_Month [Sales_Month]
      , Forecast_Year [Sales_Year]
      , Cast(Cast (Forecast_Year as varchar) + 
				'-01-' + 
				Right('0'+Cast (Forecast_Month as varchar),2) as Date) [Sales_Date]
      , Coalesce(TRANSACTIONAL_CURRENCY_CODE, 'Unknown') [TRANSACTIONAL_CURRENCY_CODE]
      , 0 Corporate_Rate
      , 0 Budgeted_Rate
      , 0 Current_Budgeted_Rate
      , 0 Sales
      , 0 Prior_Year_Sales
      , 0 Prior2_Year_Sales
      , 0 Current_Year_Sales
      , 0 Corporate_ASP_Quantity
      , 0 Prior_Year_Quantity
      , 0 Prior2_Year_Quantity
      , 0 Current_Year_Quantity
      , 0 Product_Cost
      , 0 Prior_Year_Cost
      , 0 Prior2_Year_Cost
      , 0 Current_Year_Cost
      , 0 Current_YTD_Sales
      , 0 Prior_YTD_Sales
      , 0 Prior2_YTD_Sales
      , 0 Current_QTD_Sales
      , 0 Prior_QTD_Sales
      , 0 Prior2_QTD_Sales
      , 0 Current_MTD_Sales
      , 0 Prior_MTD_Sales
      , 0 Prior2_MTD_Sales
      , 0 Current_YTD_Cost
      , 0 Prior_YTD_Cost
      , 0 Prior2_YTD_Cost
      , 0 Current_QTD_Cost
      , 0 Prior_QTD_Cost
      , 0 Prior2_QTD_Cost
      , 0 Current_MTD_Cost
      , 0 Prior_MTD_Cost
      , 0 Prior2_MTD_Cost
      , 0 Current_YTD_Quantity
      , 0 Prior_YTD_Quantity
      , 0 Prior2_YTD_Quantity
      , 0 Current_QTD_Quantity
      , 0 Prior_QTD_Quantity
      , 0 Prior2_QTD_Quantity
      , 0 Current_MTD_Quantity
      , 0 Prior_MTD_Quantity
      , 0 Prior2_MTD_Quantity
      , 0 DSR_Budget_Functional
      , 0 DSR_Budget_USD
      , 0 Exclusion_Reason
      , 0 Product_Segment_Current
      , 0 Sales_USD
      , 0 Prior_Year_Sales_USD
      , 0 Prior2_Year_Sales_USD
      , 0 Current_Year_Sales_USD
      , 0 Product_Cost_USD
      , 0 Prior_Year_Cost_USD
      , 0 Prior2_Year_Cost_USD
      , 0 Current_Year_Cost_USD
      , 0 Current_YTD_Sales_USD
      , 0 Prior_YTD_Sales_USD
      , 0 Prior2_YTD_Sales_USD
      , 0 Current_QTD_Sales_USD
      , 0 Prior_QTD_Sales_USD
      , 0 Prior2_QTD_Sales_USD
      , 0 Current_MTD_Sales_USD
      , 0 Prior_MTD_Sales_USD
      , 0 Prior2_MTD_Sales_USD
      , 0 Current_YTD_Cost_USD
      , 0 Prior_YTD_Cost_USD
      , 0 Prior2_YTD_Cost_USD
      , 0 Current_QTD_Cost_USD
      , 0 Prior_QTD_Cost_USD
      , 0 Prior2_QTD_Cost_USD
      , 0 Current_MTD_Cost_USD
      , 0 Prior_MTD_Cost_USD
      , 0 Prior2_MTD_Cost_USD
      , [Forecast_USD] * 1000 * c.Budgeted_Rate [Forecast]
      , [Forecast_USD] * 1000 [Forecast_USD]
      , 'Unknown' [PROFILE_CLASS_NAME]
      , 'Unknown' [CUSTOMER_CLASS_CODE]
	  , CASE	
			WHEN LEFT(Coalesce(Concatenated_Description, 'Unknown'),1) = '1' THEN 'Ortho'
			WHEN LEFT(Coalesce(Concatenated_Description, 'Unknown'),1) = '5' THEN 'GS'
			ELSE 'Other'
	  END
	 , getdate() Last_Update_Date
	 , 0 LC_Quota
	 , Null Ordered_Date 
	 , Null Scheduled_Ship_Date
	 , 0 [ORDERED_QUANTITY]
	 , 0 [Ord_Line_Amt_USD] 
	 , 0 [Order_Line_Amt] 
	 , Null Hold_Status
	 , Null Current_MTD_Sales_USD_PY_Rate
	 , Null Current_YTD_Sales_USD_PY_Rate
	 , Null Prior_MTD_Sales_USD_PY_Rate
	 , Null Prior_YTD_Sales_USD_PY_Rate
	 , Null Sales_USD_PY_Rate
  FROM [AS_DWH].[Tableau].[EU_Forecast] f
  Left Join [AS_DWH].[EDW].[Dim_GL_Company_Hierarchy] d
  on f.GL_Company = d.GL_COMPANY
  Left join [AS_DWH].[EDW].[Dim_GL_ACCOUNT_PRODUCT_V] p
  on f.gl_product = p.PRODUCT
  Left Join 
	(
	Select GL_Company
	, Max(operating_Unit) operating_Unit
	, Max(
			Case 
				When Operating_Unit = 'LNV_ES_OU_01' Then 'EUR'
				When Operating_Unit = 'LNV_US_OU_01' Then 'USD'
				When Operating_Unit = 'LNV_GB_OU_01' Then 'GBP'
			Else transactional_Currency_Code End) Transactional_Currency_Code
	, Max(Budgeted_Rate) Budgeted_Rate
	from as_dwh.Tableau.EU_Sales_YoY
	Where GL_Company <> '69'
	And Sales_Year = year(getdate())
	And operating_Unit <> 'Unknown'
	And Not (operating_Unit = 'LNV_ES_OU_01' And Transactional_Currency_Code <> 'EUR')
	And gl_Company Not in ('e1', '60', 'f3')
	group by GL_Company) c
  on c.GL_Company = d.GL_Company


  -- Add Quotas
Insert Into as_dwh.Tableau.EU_Sales_YoY

SELECT DescriptionF [Sales_Rep]
	  , GEOGID
      , 'Unknown' [Account_Number]
      , 'Unknown' [Account_Name]
      , 'Unknown' [Division]
      , 'Unknown' [MAJOR_DESCRIPTION]
      , 'Unknown' [MINOR_DESCRIPTION]
      , 'Unknown' [LINE_DESCRIPTION]
      , 'Unknown' [GROUP_DESCRIPTION]
      , 'Unknown' [Item_Number]
      , 'Unknown' [Item_Description]
      , 'Unknown' [Capital_Disp_Inv_Item]
      , 'Unknown' [ShipTo_Site_Name]
      , 'Unknown' [ShipToCountryName]
      , 'Unknown' [OPERATING_UNIT]
	  , 'Unknown' [GEOG2_DESCRIPTION]
      , 'Unknown' [GEOG3_DESCRIPTION]
      , 'Unknown' [GEOG4_DESCRIPTION]
      , 'Un'      [GL_Company]
      , 'Unknown' [Product_Segment_Current_BU]
      , 'Unknown' [Product_Segment_Current_Product_GRP]
      , 'Unknown' [Product_Segment_Current_Product_Sub_GRP]
      , 'Unknown' [Product_Segment_Current_OS_Brand]
      , 'Unknown' [Product_Segment_Current_Description]
      , 0 [Latitude]
      , 0 [Longitude]
      , Month(Quota_Date) [Sales_Month]
      , Year(Quota_Date) [Sales_Year]
      , Quota_Date [Sales_Date]
      , Currency_Code [TRANSACTIONAL_CURRENCY_CODE]
      , 0 Corporate_Rate
      , 0 Budgeted_Rate
      , 0 Current_Budgeted_Rate
      , 0 Sales
      , 0 Prior_Year_Sales
      , 0 Prior2_Year_Sales
      , 0 Current_Year_Sales
      , 0 Corporate_ASP_Quantity
      , 0 Prior_Year_Quantity
      , 0 Prior2_Year_Quantity
      , 0 Current_Year_Quantity
      , 0 Product_Cost
      , 0 Prior_Year_Cost
      , 0 Prior2_Year_Cost
      , 0 Current_Year_Cost
      , 0 Current_YTD_Sales
      , 0 Prior_YTD_Sales
      , 0 Prior2_YTD_Sales
      , 0 Current_QTD_Sales
      , 0 Prior_QTD_Sales
      , 0 Prior2_QTD_Sales
      , 0 Current_MTD_Sales
      , 0 Prior_MTD_Sales
      , 0 Prior2_MTD_Sales
      , 0 Current_YTD_Cost
      , 0 Prior_YTD_Cost
      , 0 Prior2_YTD_Cost
      , 0 Current_QTD_Cost
      , 0 Prior_QTD_Cost
      , 0 Prior2_QTD_Cost
      , 0 Current_MTD_Cost
      , 0 Prior_MTD_Cost
      , 0 Prior2_MTD_Cost
      , 0 Current_YTD_Quantity
      , 0 Prior_YTD_Quantity
      , 0 Prior2_YTD_Quantity
      , 0 Current_QTD_Quantity
      , 0 Prior_QTD_Quantity
      , 0 Prior2_QTD_Quantity
      , 0 Current_MTD_Quantity
      , 0 Prior_MTD_Quantity
      , 0 Prior2_MTD_Quantity
      , 0 DSR_Budget_Functional
      , 0 DSR_Budget_USD
      , 0 Exclusion_Reason
      , 0 Product_Segment_Current
      , 0 Sales_USD
      , 0 Prior_Year_Sales_USD
      , 0 Prior2_Year_Sales_USD
      , 0 Current_Year_Sales_USD
      , 0 Product_Cost_USD
      , 0 Prior_Year_Cost_USD
      , 0 Prior2_Year_Cost_USD
      , 0 Current_Year_Cost_USD
      , 0 Current_YTD_Sales_USD
      , 0 Prior_YTD_Sales_USD
      , 0 Prior2_YTD_Sales_USD
      , 0 Current_QTD_Sales_USD
      , 0 Prior_QTD_Sales_USD
      , 0 Prior2_QTD_Sales_USD
      , 0 Current_MTD_Sales_USD
      , 0 Prior_MTD_Sales_USD
      , 0 Prior2_MTD_Sales_USD
      , 0 Current_YTD_Cost_USD
      , 0 Prior_YTD_Cost_USD
      , 0 Prior2_YTD_Cost_USD
      , 0 Current_QTD_Cost_USD
      , 0 Prior_QTD_Cost_USD
      , 0 Prior2_QTD_Cost_USD
      , 0 Current_MTD_Cost_USD
      , 0 Prior_MTD_Cost_USD
      , 0 Prior2_MTD_Cost_USD
      , 0 [Forecast]
      , 0 [Forecast_USD]
      , 'Unknown' [PROFILE_CLASS_NAME]
      , 'Unknown' [CUSTOMER_CLASS_CODE]
	  , 'Unk'      GS_Ortho
	 , getdate() Last_Update_Date
	 , LC_Quota
	 , Null Ordered_Date 
	 , Null Scheduled_Ship_Date
	 , 0 [ORDERED_QUANTITY]
	 , 0 [Ord_Line_Amt_USD] 
	 , 0 [Order_Line_Amt] 
	 , Null Hold_Status
	 , Null Current_MTD_Sales_USD_PY_Rate
	 , Null Current_YTD_Sales_USD_PY_Rate
	 , Null Prior_MTD_Sales_USD_PY_Rate
	 , Null Prior_YTD_Sales_USD_PY_Rate
	 , Null Sales_USD_PY_Rate
  FROM as_dwh.Tableau.Territory_Quotas q
  Where Descriptionb in ('EUROPE & MEA', 'Latin America')
  Or descriptiond = 'ENDOSCOPIC TECHNOLOGIES'

-- Add Open Orders
Insert Into [AS_DWH].[Tableau].[EU_Sales_YoY]
	 ([Sales_Rep] ,[GeogID]  ,[Account_Number] ,[Account_Name], Latitude, Longitude
      ,[Division] ,[MAJOR_DESCRIPTION] ,[MINOR_DESCRIPTION] ,[LINE_DESCRIPTION] ,[GROUP_DESCRIPTION]
      ,[Item_Number] ,[Item_Description] ,[Capital_Disp_Inv_Item]
      ,[ShipTo_Site_Name] ,[ShipToCountryName]
      ,[OPERATING_UNIT]  ,GEOG2_DESCRIPTION ,[GEOG3_DESCRIPTION] ,[GEOG4_DESCRIPTION]
      ,[GL_Company] ,[Product_Segment_Current_BU] ,[Product_Segment_Current_Product_GRP] 
	  ,[Product_Segment_Current_Product_Sub_GRP] ,[GS_Ortho]
      ,[Product_Segment_Current_OS_Brand]  ,[Product_Segment_Current_Description] ,[Product_Segment_Current]
      ,[TRANSACTIONAL_CURRENCY_CODE]  
      ,[PROFILE_CLASS_NAME] ,[CUSTOMER_CLASS_CODE] ,[Last_UpDate_Date]
	  , Ordered_Date , Scheduled_Ship_Date, [ORDERED_QUANTITY], [Ord_Line_Amt_USD] 
	  , [Order_Line_Amt] , Hold_Status)

SELECT g.descriptionf SalesRep ,g.GEOGID, stcl.Account_Number , stcl.Account_Name, stcl.Latitude, stcl.Longitude
	  , ic.Division , ic.MAJOR_DESCRIPTION , ic.MINOR_DESCRIPTION , ic.LINE_DESCRIPTION , ic.GROUP_DESCRIPTION
	  , p.Item_Number ,p.description, it.Source Cap_Disp
	  , stcl.location ShipTo_Site_Name ,stcl.COUNTRY_NAME [ShipToCountryName]
      , ou.name [OPERATING_UNIT]
	  , glc.[GEOG2_DESCRIPTION]
      , glc.[GEOG3_DESCRIPTION]
      , glc.[GEOG4_DESCRIPTION]
	  , glc.[GL_Company]
	  , glp.[Business_Unit]  ,glp.[Product_Group] 
	  , glp.[Product_Subgroup] ,glp.GS_Ortho
	  , glp.[OneStream_Brand_Name] ,glp.[PRODUCT_DESCRIPTION] , glp.[PRODUCT] ,[TRANSACTIONAL_CURRENCY_CODE]
	  , stcl.[PROFILE_CLASS_NAME] ,stcl.[CUSTOMER_CLASS_CODE], getdate()
	  , Cast(od.ActualDate as Date) Ordered_Date
	  ,  Cast(ssd.ActualDate as Date) Scheduled_Ship_Date
	  , [ORDERED_QUANTITY]  
	  , [Order_Line_Amt] / br.CONVERSION_RATE [Ord_Line_Amt_USD] 
	  , [Order_Line_Amt] , hs.Hold_Status
  FROM [AS_DWH].[EDW].[Fact_SALES_OPEN_ORDER] f
  Inner Join as_dwh.dbo.Timemaster od
  On f.[Dim_ORDERED_DATE_KEY] = od.dayid
  Inner Join as_dwh.dbo.Timemaster ssd
  On f.[Dim_SCH_SHIP_DATE_KEY] = ssd.dayid
  inner join as_dwh.edw.Dim_SHIP_TO_CUSTOMER_LOCATION_v stcl
  on stcl.[Dim_CUSTOMER_LOCATION_KEY] = f.[Dim_SHIP_TO_CUSTOMER_LOCATION_KEY]
  Inner Join as_dwh.edw.Dim_PRODUCT_Combined_V p
  on p.[Dim_PRODUCT_KEY] = f.Dim_PRODUCT_KEY
  Inner Join as_dwh.edw.Dim_OPERATING_UNIT_V OU
  on ou.[Dim_Operating_Unit_KEY] = f.[Dim_Operating_Unit_KEY]
  Inner Join as_dwh.dbo.Dim_CONMED_ITEM_CATEGORY ic
  on p.Dim_Conmed_Item_Category_Key = ic.Dim_Conmed_Item_Category_Key
  Inner Join as_dwh.dbo.Dim_Linvatec_ITEM_Type_CATEGORY it
  on p.Dim_Linvatec_Item_Type_Category_Key = it.Dim_Linvatec_Item_Type_Category_Key
  inner join as_dwh.edw.Dim_Hold_Status hs
  on hs.[Dim_Hold_Status_Key] = f.[Dim_Hold_Status_Key]
  inner join as_dwh.dbo.Dim_Sales_Geography g
  on g.Dim_Sales_Geography_Key = f.Dim_Sales_Geography_Key
  inner join as_dwh.[dbo].[Dim_GL_ACCOUNT] gl
  on p.[SALES_ACCOUNT] = gl.[ORACLE_CODE_COMBINATION_ID]
  Inner join [EDW].[Dim_GL_ACCOUNT_PRODUCT_V] glp
  On gl.Product = glp.[PRODUCT]
  Inner join dbo.[Dim_Pricelist] pl
  On pl.Dim_PRICELIST_KEY = f.Dim_PRICE_LIST_KEY
  Inner Join [AS_DWH].[dbo].Dim_ORDER_TYPE OHT
  on oht.Dim_ORDER_TYPE_KEY = f.Dim_ORDER_HEADER_TYPE_KEY
  inner Join AS_DWH.EDW.Dim_GL_COMPANY_Hierarchy glc
  on f.Dim_GL_COMPANY_Hierarchy_key = glc.Dim_GL_COMPANY_Hierarchy_key
  inner Join 
	(select datepart(YYYY ,conversion_date ) AS COST_YEAR 
			, TO_CURRENCY
			, MAX(conversion_rate) AS CONVERSION_RATE 
	from dw_main.dbo.gl_daily_rates
	where CONVERSION_TYPE in ( '1002') 
	and FROM_CURRENCY = 'USD'
	group by  TO_CURRENCY, datepart(YYYY ,conversion_date )
	) br
  On br.COST_YEAR = YEAR(Getdate())
  And br.TO_CURRENCY = f.Transactional_Currency_Code
Where p.dim_Product_Key <> 0
And Left(glp.Product,1) in ('1', '5')
And (glc.Geog1_description = 'International'or descriptiond = 'ENDOSCOPIC TECHNOLOGIES')
--descriptionb in ('EUROPE & MEA', 'LATIN AMERICA') 
And OHT.TRANSACTION_TYPE_NAME not like 'HOUSE EVAL%' and  OHT.TRANSACTION_TYPE_NAME not like 'ADVANTAGE%'


-- Create Prior Year Budget Rate Columns

  Update as_dwh.Tableau.EU_Sales_YoY
	Set   Current_MTD_Sales_USD_PY_Rate = Current_MTD_Sales / Coalesce(pbr.CONVERSION_RATE,1) 
		, Current_YTD_Sales_USD_PY_Rate = Current_YTD_Sales / Coalesce(pbr.CONVERSION_RATE,1)  
		, Prior_MTD_Sales_USD_PY_Rate   = Prior_MTD_Sales	/ Coalesce(pbr.CONVERSION_RATE,1)  
		, Prior_YTD_Sales_USD_PY_Rate   = Prior_YTD_Sales	/ Coalesce(pbr.CONVERSION_RATE,1)  
		, Sales_USD_PY_Rate				= Sales				/ Coalesce(pbr.CONVERSION_RATE,1) 

  From as_dwh.Tableau.EU_Sales_YoY d
  Left Join 
	(select datepart(YYYY ,conversion_date ) AS COST_YEAR 
			, TO_CURRENCY
			, MAX(conversion_rate) AS CONVERSION_RATE 
	from dw_main.dbo.gl_daily_rates
	where CONVERSION_TYPE in ( '1002') 
	and FROM_CURRENCY = 'USD'
	group by  TO_CURRENCY, datepart(YYYY ,conversion_date )
	) pbr
  On pbr.COST_YEAR = YEAR(Getdate()) -1
  And pbr.TO_CURRENCY = d.Transactional_Currency_Code
  Where Current_MTD_Sales is not null
  
  End

CREATE NONCLUSTERED INDEX Tableau_EU_YoY_Acct_idx ON Tableau.EU_Sales_YoY
(Account_Number ,Account_Name, ShipTo_Site_Name ASC)
CREATE NONCLUSTERED INDEX Tableau_EU_YoY_Prod_idx ON Tableau.EU_Sales_YoY
(Item_Number, Item_Description ASC)
CREATE NONCLUSTERED INDEX Tableau_EU_YoY_ICat_idx ON Tableau.EU_Sales_YoY
(Division, MAJOR_DESCRIPTION ,MINOR_DESCRIPTION, LINE_DESCRIPTION, GROUP_DESCRIPTION ASC)
CREATE NONCLUSTERED INDEX Tableau_EU_YoY_Rep_idx ON Tableau.EU_Sales_YoY
(Sales_Rep, GEOGID ASC)
CREATE NONCLUSTERED INDEX Tableau_EU_YoY_CTRY_idx ON Tableau.EU_Sales_YoY
(ShipToCountryName, OPERATING_UNIT, gl_Company ASC)
CREATE NONCLUSTERED INDEX Tableau_EU_YoY_BU_idx ON Tableau.EU_Sales_YoY
(Product_Segment_Current_BU, Product_Segment_Current_Product_GRP
	, Product_Segment_Current_Product_Sub_GRP, Product_Segment_Current_Description
	, Product_Segment_Current, GS_Ortho ASC)
CREATE NONCLUSTERED INDEX Tableau_EU_YoY_Date_idx ON Tableau.EU_Sales_YoY
(Sales_Month, Sales_Year, Sales_Date ASC)
CREATE NONCLUSTERED INDEX Tableau_EU_YoY_Cap_Disp_idx ON Tableau.EU_Sales_YoY
(Capital_Disp_Inv_Item ASC)
CREATE NONCLUSTERED INDEX Tableau_EU_YoY_Cust_Class_idx ON Tableau.EU_Sales_YoY
(PROFILE_CLASS_NAME, CUSTOMER_CLASS_CODE ASC)


