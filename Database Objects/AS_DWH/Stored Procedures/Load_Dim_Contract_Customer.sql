USE [AS_DWH]
GO
/****** Object:  StoredProcedure [dbo].[Load_Dim_Contract_Customer]    Script Date: 5/2/2018 12:54:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Perry Parsino
-- Create date: 03.11.2018
-- Last Modification By: 
-- Last Modification Date:
-- Description:	Load Dim_Contract_Customer
-- =============================================
ALTER Procedure [dbo].[Load_Dim_Contract_Customer]      
AS

SET nocount ON;
BEGIN
-- edw Dim_Contract_Customer - Procedure

Truncate Table as_Stage.dbo.stg_edw_Dim_Contract_Customer
Insert Into as_Stage.dbo.stg_edw_Dim_Contract_Customer

Select mc.Dim_SHIP_TO_CUSTOMER_LOCATION_key
	, [Dim_Definitive_Attributes_Key]
	, mc.definitive Definitive_ID
	, Max(Case
		When [Hospital_Name] = 'Unaffiliated' Then
			mc.[IDN_Parent]
		Else [Hospital_Name]
		End) Hospital_Name
	, Max(mc.[IDN_Parent]) [IDN_Parent]
	, Max(da.[IDN]) [IDN]
	, Max(mc.rpc) rpc
from [AS_STAGE].[dbo].[LU_Contracts_Customer] mc
inner join as_dwh.edw.Dim_SHIP_TO_CUSTOMER_LOCATION_V cl
on mc.Dim_SHIP_TO_CUSTOMER_LOCATION_key = cl.Dim_CUSTOMER_LOCATION_key
Inner join as_dwh.edw.Dim_Definitive_Attributes da
on mc.definitive = da.[Definitive_ID]
group by mc.Dim_SHIP_TO_CUSTOMER_LOCATION_key
	, [Dim_Definitive_Attributes_Key]
	, mc.definitive


MERGE INTO as_dwh.edw.Dim_Contract_Customer DIM
USING as_Stage.dbo.stg_edw_Dim_Contract_Customer STG
 ON DIM.Dim_SHIP_TO_CUSTOMER_LOCATION_key = STG.Dim_SHIP_TO_CUSTOMER_LOCATION_key
And DIM.Definitive_ID = STG.Definitive_ID
WHEN MATCHED THEN UPDATE SET
 DIM.Hospital_Name	= Left(STG.Hospital_Name, 100),
 DIM.IDN_Parent		= Left(STG.IDN_Parent, 100),
 DIM.IDN			= Left(STG.IDN, 100),
 DIM.Dim_Definitive_Attributes_Key = STG.Dim_Definitive_Attributes_Key,
 DIM.RPC = STG.RPC
 WHEN NOT MATCHED BY TARGET THEN
 INSERT (Dim_SHIP_TO_CUSTOMER_LOCATION_key	,Dim_Definitive_Attributes_Key,
		 Hospital_Name,	IDN_Parent,	IDN, Definitive_ID, RPC)
 VALUES (STG.Dim_SHIP_TO_CUSTOMER_LOCATION_key	,STG.Dim_Definitive_Attributes_Key,
		 Left(STG.Hospital_Name, 100),	Left(STG.IDN_Parent, 100),	Left(STG.IDN, 100)
		 , STG.Definitive_ID, Left(STG.RPC, 100))
WHEN NOT MATCHED BY Source THEN
  DELETE;;

END 