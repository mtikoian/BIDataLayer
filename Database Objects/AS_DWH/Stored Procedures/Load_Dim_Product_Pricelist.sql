USE [AS_DWH]
GO
/****** Object:  StoredProcedure [dbo].[Load_Dim_Product_Pricelist]    Script Date: 5/2/2018 12:56:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Perry Parsino
-- Create date: 03.05.2018
-- Last Modification By: 
-- Last Modification Date:
-- Description:	Load Dim_Product_Pricelist
-- =============================================
ALTER Procedure [dbo].[Load_Dim_Product_Pricelist]      
AS

SET nocount ON;
BEGIN


-- Oracle Data
Truncate Table as_Stage.dbo.stg_edw_Dim_Product_Pricelist_Loader
Insert Into as_Stage.dbo.stg_edw_Dim_Product_Pricelist_Loader

SELECT si.Dim_Product_Key
		, pl.Dim_PRICELIST_KEY
		, Max(LL.LIST_HEADER_ID) LIST_HEADER_ID
		, Max(LL.LIST_LINE_ID) LIST_LINE_ID
		, Min(LL.START_DATE_ACTIVE) START_DATE_ACTIVE
		, Max(Coalesce(ll.end_date_active,getdate())) END_DATE_ACTIVE
		, Max(SI.Item_Number) Item_Number
		, Max(SI.DESCRIPTION) ITEM_DESCRIPTION
FROM dw_main.dbo.QP_LIST_LINES LL
Inner Join dw_main.dbo.QP_PRICING_ATTRIBUTES PA
on LL.LIST_LINE_ID = PA.LIST_LINE_ID
AND PA.PRODUCT_ATTRIBUTE = 'PRICING_ATTRIBUTE1'
Inner Join as_dwh.dbo.Dim_Product SI
on cast(PA.PRODUCT_ATTR_VALUE AS float) = SI.Oracle_INVENTORY_ITEM_ID
AND SI.Oracle_ORGANIZATION_ID = 155
Inner Join [AS_DWH].[dbo].[Dim_PRICELIST] pl
on pl.ORACLE_LIST_HEADER_ID = LL.LIST_HEADER_ID
Where Coalesce(ll.end_date_active,getdate()) > Dateadd(year, -3, getdate()) --'2015-01-01' 
And pl.ACTIVE_FLAG = 'Yes'
and pl.currency_Code = 'usd'
And ll.end_date_active is not null
--And ll.Start_date_active is not null
--And LL.LIST_HEADER_ID in (5046852)
Group by si.Dim_Product_Key
		, pl.Dim_PRICELIST_KEY


MERGE INTO as_Stage.dbo.stg_edw_Dim_Product_Pricelist DIM
USING as_Stage.dbo.stg_edw_Dim_Product_Pricelist_Loader STG
 ON DIM.Dim_Product_Key = STG.Dim_Product_Key
 And DIM.Dim_PRICELIST_KEY = STG.Dim_PRICELIST_KEY
WHEN MATCHED THEN UPDATE SET
 DIM.LIST_HEADER_ID = STG.LIST_HEADER_ID,
 DIM.LIST_LINE_ID = STG.LIST_LINE_ID,
 DIM.START_DATE_ACTIVE = STG.START_DATE_ACTIVE,
 DIM.END_DATE_ACTIVE = STG.END_DATE_ACTIVE,
 DIM.Item_Number = STG.Item_Number,
 DIM.ITEM_DESCRIPTION = STG.ITEM_DESCRIPTION
WHEN NOT MATCHED BY TARGET THEN
 INSERT (Dim_Product_Key, Dim_PRICELIST_KEY, LIST_HEADER_ID, LIST_LINE_ID, 
   START_DATE_ACTIVE, END_DATE_ACTIVE, Item_Number, ITEM_DESCRIPTION)
 VALUES (STG.Dim_Product_Key, STG.Dim_PRICELIST_KEY, STG.LIST_HEADER_ID, STG.LIST_LINE_ID,
   STG.START_DATE_ACTIVE, STG.END_DATE_ACTIVE, STG.Item_Number, STG.ITEM_DESCRIPTION);

Truncate Table as_dwh.edw.Dim_Product_Pricelist
Insert Into as_dwh.edw.Dim_Product_Pricelist
Select * from as_Stage.dbo.stg_edw_Dim_Product_Pricelist

-- Manman Data
Truncate Table as_Stage.dbo.stg_edw_Dim_Product_Pricelist_Loader
Insert Into as_Stage.dbo.stg_edw_Dim_Product_Pricelist_Loader

SELECT Distinct p.Dim_Product_Key
		, pl.Dim_PRICELIST_KEY
		, 0 LIST_HEADER_ID
		, 0 LIST_LINE_ID
		, Getdate() START_DATE_ACTIVE
		, getdate() END_DATE_ACTIVE
		, p.Item_Number
		, p.DESCRIPTION ITEM_DESCRIPTION
FROM as_dwh.edw.fact_Sales_Order f
Inner Join as_dwh.edw.Dim_Product_Combined_v p
on f.Dim_Product_Key = p.Dim_Product_Key
Inner Join as_dwh.edw.Dim_Pricelist pl
on f.Dim_Price_list_Key = pl.Dim_Pricelist_Key
And pl.Dim_Pricelist_Key < 0

MERGE INTO as_Stage.dbo.stg_edw_Dim_Product_Pricelist_Manman DIM
USING as_Stage.dbo.stg_edw_Dim_Product_Pricelist_Loader STG
 ON DIM.Dim_Product_Key = STG.Dim_Product_Key
 And DIM.Dim_PRICELIST_KEY = STG.Dim_PRICELIST_KEY
WHEN MATCHED THEN UPDATE SET
 DIM.LIST_HEADER_ID = STG.LIST_HEADER_ID,
 DIM.LIST_LINE_ID = STG.LIST_LINE_ID,
 DIM.START_DATE_ACTIVE = STG.START_DATE_ACTIVE,
 DIM.END_DATE_ACTIVE = STG.END_DATE_ACTIVE,
 DIM.Item_Number = STG.Item_Number,
 DIM.ITEM_DESCRIPTION = STG.ITEM_DESCRIPTION
WHEN NOT MATCHED BY TARGET THEN
 INSERT (Dim_Product_Key, Dim_PRICELIST_KEY, LIST_HEADER_ID, LIST_LINE_ID, 
   START_DATE_ACTIVE, END_DATE_ACTIVE, Item_Number, ITEM_DESCRIPTION)
 VALUES (STG.Dim_Product_Key, STG.Dim_PRICELIST_KEY, STG.LIST_HEADER_ID, STG.LIST_LINE_ID,
   STG.START_DATE_ACTIVE, STG.END_DATE_ACTIVE, STG.Item_Number, STG.ITEM_DESCRIPTION);

Insert Into as_dwh.edw.Dim_Product_Pricelist
Select * from as_Stage.dbo.stg_edw_Dim_Product_Pricelist_Manman


END 
