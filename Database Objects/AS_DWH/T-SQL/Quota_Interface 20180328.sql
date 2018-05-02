
-- Load all Production quotas to interface table
-- After doing this load to final import from Ortho ss or use interface
Truncate Table [Application].[dbo].[Quota_Interface]
Insert Into [Application].[dbo].[Quota_Interface]

SELECT Cast(t.ActualDate as Date) [Quota_Date]
	  , Case
			When Level = 'f' Then idf
			When Level = 'e' Then ide
			When Level = 'd' Then idd
			When Level = 'c' Then idc
			End [id]
      , Case
			When Level = 'f' Then geogid
			Else ' '
			End Geogid
      , 'DISPOSABLE' [Category_Type]
      , 0 [USD_Quota]
      , Quota [LC_Quota]
	  , ' ' [CURRENCY_CODE]
  FROM [AS_DWH].[EDW].[Fact_Quotas_V] f
  Inner Join as_dwh.dbo.TimeMaster t
  on f.Dim_COMM_SALES_KEY = t.dayid
  Inner Join as_dwh.edw.Dim_Sales_Geography_v g
  on f.[Dim_SALES_GEOGRAPHY_KEY] = g.[Dim_SALES_GEOGRAPHY_KEY]