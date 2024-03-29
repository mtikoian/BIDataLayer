USE [AS_DWH]
GO
/****** Object:  StoredProcedure [dbo].[Load_Dim_Definitive_Attributes]    Script Date: 5/2/2018 12:55:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Perry Parsino
-- Create date: 03.10.2018
-- Last Modification By: 
-- Last Modification Date:
-- Description:	Load Dim_Definitive_Attributes
-- =============================================
ALTER Procedure [dbo].[Load_Dim_Definitive_Attributes]      
AS

SET nocount ON;
BEGIN
-- delete dups
delete
from [AS_DWH].[gis].[Definitive_Health_Care_All]
Where [Definitive ID] in (
	Select [Definitive ID]
	from [AS_DWH].[gis].[Definitive_Health_Care_All] STG
	Group by [Definitive ID]
	Having count(*) > 1)


MERGE INTO as_dwh.[edw].Dim_Definitive_Attributes DIM
USING [AS_DWH].[gis].[Definitive_Health_Care_All] STG
 ON DIM.[Definitive_ID] = STG.[Definitive ID]
WHEN MATCHED THEN UPDATE SET
 DIM.[Firm_Type]		= STG.[Firm Type],
 DIM.[Hospital_Type]	= STG.[Hospital Type],
 DIM.[Hospital_Name]	=STG.[Hospital Name],
 DIM.[Address]			=STG.[Address],
 DIM.[Address1]			=STG.[Address1],
 DIM.[City]				=STG.[City],
 DIM.[State]			=STG.[State],
 DIM.[Zip_Code]			=STG.[Zip Code],
 DIM.[IDN]				=STG.[IDN],
 DIM.[Definitive_ID]	=STG.[Definitive ID],
 DIM.[IDN_Parent]		=STG.[IDN Parent],
 DIM.[Net_Patient_Revenue]=STG.[Net Patient Revenue],
 DIM.[#_of_Discharges]	=STG.[# of Discharges],
 DIM.[#_of_Staffed_Beds]=STG.[# of Staffed Beds],
 DIM.[Latitude]			=STG.[Latitude],
 DIM.[Longitude]		=STG.[Longitude],
 DIM.[Outpatient_Revenue]=STG.[Outpatient Revenue],
 DIM.[Inpatient_Revenue]	=STG.[Inpatient Revenue],
 DIM.[Adjusted_Patient_Days]=STG.[Adjusted Patient Days],
 DIM.[Est_#_of_Inpatient_Surgeries]=STG.[Est # of Inpatient Surgeries],
 DIM.[Est_#_of_Outpatient_Visits]=STG.[Est # of Outpatient Visits],
 DIM.[Number_of_Operating_Rooms]=STG.[Number of Operating Rooms],
 DIM.[GPO_Affiliations] =Left(STG.[GPO_Affiliations], 100),
 DIM.[Net_Patient_Revenue_Range]= STG.[Net_Patient_Revenue],
 DIM.[Number_Operating_Rooms]= STG.[Number_Operating_Rooms],
 DIM.[Number_Staffed_Beds] =STG.[Number_Staffed_Beds],
 DIM.[Number_Discharges]=STG.[Number_Discharges]
WHEN NOT MATCHED BY TARGET THEN
 INSERT ([Firm_Type],[Hospital_Type], [Hospital_Name], [Address], [Address1], [City] 
 ,[State],[Zip_Code], [IDN], [Definitive_ID], [IDN_Parent], [Net_Patient_Revenue]
 ,[#_of_Discharges] ,[#_of_Staffed_Beds] ,[Latitude] ,[Longitude] ,[Outpatient_Revenue]
 ,[Inpatient_Revenue] ,[Adjusted_Patient_Days] ,[Est_#_of_Inpatient_Surgeries]
 ,[Est_#_of_Outpatient_Visits] ,[Number_of_Operating_Rooms] ,[GPO_Affiliations] 
 ,[Net_Patient_Revenue_Range]  ,[Number_Operating_Rooms]  ,[Number_Staffed_Beds] 
 ,[Number_Discharges])
 VALUES (STG.[Firm Type] ,STG.[Hospital Type] ,STG.[Hospital Name] ,STG.[Address] 
 ,STG.[Address1] ,STG.[City] ,STG.[State] ,STG.[Zip Code] ,STG.[IDN] ,STG.[Definitive ID]
 ,STG.[IDN Parent] ,STG.[Net Patient Revenue] ,STG.[# of Discharges] ,STG.[# of Staffed Beds]
 ,STG.[Latitude] ,STG.[Longitude] ,STG.[Outpatient Revenue] ,STG.[Inpatient Revenue]
 ,STG.[Adjusted Patient Days] ,STG.[Est # of Inpatient Surgeries] ,STG.[Est # of Outpatient Visits]
 ,STG.[Number of Operating Rooms] ,Left(STG.[GPO_Affiliations], 100)  ,STG.[Net_Patient_Revenue] 
 ,STG.[Number_Operating_Rooms]  ,STG.[Number_Staffed_Beds]  ,STG.[Number_Discharges]);

 
END 