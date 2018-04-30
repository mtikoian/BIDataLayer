USE [AS_DWH]
GO

/****** Object:  StoredProcedure [dbo].[Load_Dim_Inventory_Lot_Serial_Number]    Script Date: 4/30/2018 3:05:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Jane Datz>
-- Create date: <20180406>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Load_Dim_Inventory_Lot_Serial_Number]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   truncate table as_dwh.[dbo].[Dim_Inventory_Lot_Serial_Number]
--Org_ID float
--unknown row
insert into as_dwh.[dbo].[Dim_Inventory_Lot_Serial_Number]
([ORDER_NUMBER],
	[ORDERED_ITEM],
	Org_ID,
	Snap_Shot_Date,
	[SERIAL_NUMBER],
	[LOT_NUMBER],
	[R_SERIAL_NUMBER],
	[R_LOT_NUMBER],
	[KIT_ITEM],
	[KIT_SER_NUMBER]
	, Report
	,Org_Location
	,Basis_Date
  , Basis_Months
	)
	select 
	0
	,0
	,0
	,NULL
	,'unknown'
	,'unknown'
	,'unknown'
	,'unknown'
	,'unknown'
	, 'unknown'
	,'unknown'
	, 'unknown'
	,NULL
	,NULL;
	

insert into as_dwh.[dbo].[Dim_Inventory_Lot_Serial_Number]
([ORDER_NUMBER],
	[ORDERED_ITEM],
	Org_ID,
	Snap_Shot_Date,
	[SERIAL_NUMBER],
	[LOT_NUMBER],
	[R_SERIAL_NUMBER],
	[R_LOT_NUMBER],
	[KIT_ITEM],
	[KIT_SER_NUMBER],
	Report
	,Org_Location
	,Basis_Date
  , Basis_Months
	)
SELECT IsNull([ORDER_NUMBER], 0) Order_Number
      ,[ORDERED_ITEM]
	  ,Org_ID
	  ,dateadd(dd, -1, cast(cast(datepart(mm,[Snapshot_DATE]) as varchar(2)) + '/01/' + 
	  cast(datepart(yyyy,[Snapshot_DATE]) as varchar(4)) as date)) as [Snapshot_DATE]
      ,IsNull([SERIAL_NUMBER], 'unknown')
      ,IsNull([LOT_NUMBER], 'unknown')
      ,[R_SERIAL_NUMBER]
      ,[R_LOT_NUMBER]
      ,[KIT_ITEM]
      ,[KIT_SER_NUMBER]
	  ,'LNV_ADVT_EXT'
	  ,'Advantage'
	  , Basis_Date
	  , Basis_Months
 FROM [AS_STAGE].[dbo].[stg_Advantage_Extract]
  union
  select 
	IsNull([ORDER_NUMBER], 0) Order_Number
  ,[ORDERED_ITEM]
  ,Org_ID
  ,dateadd(dd, -1, cast(cast(datepart(mm,[Snapshot_DATE]) as varchar(2)) + '/01/' + 
	  cast(datepart(yyyy,[Snapshot_DATE]) as varchar(4)) as date)) as [Snapshot_DATE]
  ,IsNull([R_SERIAL_NUMBER], 'unknown')
  ,IsNull([R_LOT_NUMBER], 'unknown')
  ,  'unknown'
  ,  'unknown'
  ,[KIT_ITEM]
  ,[KIT_SER_NUMBER]
  ,'LNV_House_Report'
  , 'House'
  , Basis_Date
  , Basis_Months
from 	[AS_STAGE].[dbo].[stg_LNV_HOUSE_EXT]
  union
  select
  0 Order_Number
  ,ITEM
  ,Org_ID
  ,dateadd(dd, -1, cast(cast(datepart(mm,[Snapshot_DATE]) as varchar(2)) + '/01/' + 
	  cast(datepart(yyyy,[Snapshot_DATE]) as varchar(4)) as date)) as [Snapshot_DATE]
  ,IsNull([SERIAL_NUMBER], 'unknown')
  ,IsNull([LOT_NUMBER], 'unknown')
  ,IsNull([R_SERIAL_NUMBER], 'unknown')
  , IsNull([R_LOT_NUMBER], 'unknown')
  ,IsNull([KIT_ITEM], 'unknown')
  ,IsNull([KIT_SER_NUMBER], 'unknown')
  ,'LVN_OUS_Sample_Report'
  ,'LBD'
  ,Basis_Date
  , Basis_Months
 from 	[AS_STAGE].[dbo].[stg_LNV_SAMPLE_INV_V]



END
GO


