USE [AS_DWH]
GO
/****** Object:  StoredProcedure [dbo].[Load_Dim_Contracts_Reporting]    Script Date: 5/2/2018 12:55:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Perry Parsino
-- Create date: 03.11.2018
-- Last Modification By: 
-- Last Modification Date:
-- Description:	Load Dim_Contracts_Reporting
-- =============================================
ALTER Procedure [dbo].[Load_Dim_Contracts_Reporting]      
AS

SET nocount ON;
BEGIN

-- edw Dim_Contracts_Reporting

MERGE INTO as_dwh.edw.Dim_Contracts_Reporting DIM
USING [AS_DWH].[gis].[LU_Contracts_Hierarchy] STG
 ON DIM.Dim_CUSTOMER_LOCATION_KEY = STG.Dim_CUSTOMER_LOCATION_KEY
WHEN MATCHED THEN UPDATE SET
 DIM.Region						= STG.Region,
 DIM.ShipTo_Location_Number		= STG.ShipTo_Location_Number,
 DIM.IDN						=STG.IDN,
 DIM.Contract_Manager			=STG.Contract_Manager,
 DIM.Contract_Category			=STG.Contract_Category,
 DIM.IDN_Parent					=STG.IDN_Parent,
 DIM.Source						=STG.Source,
 DIM.DEFFC_ID					=STG.DEFFC_ID
 WHEN NOT MATCHED BY TARGET THEN
 INSERT (Region	,ShipTo_Location_Number, IDN, Contract_Manager, Contract_Category, 
		 Dim_CUSTOMER_LOCATION_KEY,	IDN_Parent,	Source,	DEFFC_ID)
 VALUES (STG.Region	,STG.ShipTo_Location_Number, STG.IDN, STG.Contract_Manager, STG.Contract_Category, 
		 STG.Dim_CUSTOMER_LOCATION_KEY,	STG.IDN_Parent,	STG.Source,	STG.DEFFC_ID);
		  
END 