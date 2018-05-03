USE [AS_DWH]
GO

/****** Object:  View [EDW].[Dim_PRODUCT_Combined_Sales_Cube_V]    Script Date: 5/2/2018 1:01:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







CREATE view [EDW].[Dim_PRODUCT_Combined_Sales_Cube_V]
as (
Select *
from as_dwh.edw.Dim_Product_Combined_V
Where Dim_Product_Key in
	(Select distinct dim_product_Key
	from as_dwh.edw.fact_sales_order)
Or Dim_Product_Key in
	(Select distinct dim_product_Key
	from as_dwh.edw.fact_sales_open_order)
Or Dim_Product_Key in
	(Select distinct dim_product_Key
	from  as_dwh.edw.Fact_Net_Open_Orders)
  
)







































GO


