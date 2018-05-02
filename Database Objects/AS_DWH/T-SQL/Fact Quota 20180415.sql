-- Fact Quota

-- Create Quota Level Dimension which is unioned with the Sales Geography
-- Final view is as_dwh.edw.Dim_Sales_Geography_v
TRUNCATE TABLE As_DWH.EDW.Dim_SALES_GEOGRAPHY_QUOTALVL
DBCC CHECKIDENT ([As_DWH.EDW.Dim_SALES_GEOGRAPHY_QUOTALVL], RESEED, -1);
go

INSERT INTO As_DWH.EDW.Dim_SALES_GEOGRAPHY_QUOTALVL
	
Select IDA, DESCRIPTIONA, IDB, DESCRIPTIONB, IDC, DESCRIPTIONC
	, 'DQ11' + CAST(Right(idc, Len(idc)-1) As Varchar) IDD
	, Left(Rtrim(DescriptionC),44) + ' Quota'	DESCRIPTIOND
	, 'EQ22' + CAST(Right(idc, Len(idc)-1) As Varchar) IDE
	, Left(Rtrim(DescriptionC),44) + ' Quota' DESCRIPTIONE
	, 'FQ33' + CAST(Right(idc, Len(idc)-1) As Varchar) IDF
	, Left(Rtrim(DescriptionC),44) + ' Quota' DESCRIPTIONF
	, 'QQ44' + CAST(Right(idc, Len(idc)-1) As Varchar) GEOGID
from as_dwh.dbo.Dim_SALES_GEOGRAPHY g
Where IDC in (	
	Select Distinct ID
	from [Application].[dbo].[Quota_Interface] i
	Where Left(id,1) = 'C')
And idc not in (
	Select Distinct idc
	from [AS_DWH].EDW.Dim_SALES_GEOGRAPHY_QUOTALVL
	Where descriptiond like '%quota%')
Group by IDA, DESCRIPTIONA, IDB, DESCRIPTIONB, IDC, DESCRIPTIONC

Union All 

Select IDA, DESCRIPTIONA, IDB, DESCRIPTIONB, IDC, DESCRIPTIONC, IDD, DESCRIPTIOND
	, 'EQ11' + CAST(Right(idd, Len(idd)-1) As Varchar) IDE
	, Left(Rtrim(DESCRIPTIOND),44) + ' Quota' DESCRIPTIONE
	, 'FQ22' + CAST(Right(idd, Len(idd)-1) As Varchar) IDF
	, Left(Rtrim(DESCRIPTIOND),44) + ' Quota' DESCRIPTIONF
	, 'QQ33' + CAST(Right(idd, Len(idd)-1) As Varchar) GEOGID
from as_dwh.dbo.Dim_SALES_GEOGRAPHY g
Where IDD in (	
	Select Distinct ID
	from [Application].[dbo].[Quota_Interface] i
	Where Left(id,1) = 'D')
And idd not in (
	Select Distinct idd
	from [AS_DWH].EDW.Dim_SALES_GEOGRAPHY_QUOTALVL
	Where descriptione like '%quota%')
Group by IDA, DESCRIPTIONA, IDB, DESCRIPTIONB, IDC, DESCRIPTIONC, IDD, DESCRIPTIOND

Union All 

Select IDA, DESCRIPTIONA, IDB, DESCRIPTIONB, IDC, DESCRIPTIONC, IDD, DESCRIPTIOND, IDE, DESCRIPTIONE
	, 'FQ11' + CAST(Right(ide, Len(ide)-1) As Varchar) IDF
	, Left(Rtrim(DESCRIPTIONE),44) + ' Quota' DESCRIPTIONF
	, 'QQ22' + CAST(Right(ide, Len(ide)-1) As Varchar) GEOGID
from as_dwh.dbo.Dim_SALES_GEOGRAPHY g
Where IDE in (	
	Select Distinct ID
	from [Application].[dbo].[Quota_Interface] i
	Where Left(id,1) = 'E')
And ide not in (
	Select Distinct ide
	from [AS_DWH].EDW.Dim_SALES_GEOGRAPHY_QUOTALVL
	Where descriptionf like '%quota%')
Group by IDA, DESCRIPTIONA, IDB, DESCRIPTIONB, IDC, DESCRIPTIONC, IDD, DESCRIPTIOND, IDE, DESCRIPTIONE


Truncate Table as_dwh.edw.Fact_Quota
Insert Into as_dwh.edw.Fact_Quota

Select g.Dim_sales_Geography_Key
	, t.dayid  Dim_Quota_Date_Key 
	, Coalesce(c.Dim_Currency_Key, 0) Dim_Currency_Key
	, Category_Type Capital_Disposable
	, id
	, ' ' Description
	, Case Left(id,1)
		When 'F' Then 7
		When 'E' Then 6
		When 'D' Then 5
		When 'C' Then 4
		Else 0 
	  End TreeLevel
	, USD_Quota
	, LC_Quota

from [Application].[dbo].[Quota_Interface] i
left join as_dwh.dbo.timemaster t
on i.quota_date = t.actualDate
left join as_dwh.dbo.Dim_Currency c
on i.Currency_Code = c.Currency_Code
left join as_DWH.edw.Dim_Sales_Geography_V g
on i.id = Case Left(id,1)
			When 'F' Then idf
			When 'E' Then ide
			When 'D' Then idd
			When 'C' Then idc
			Else idb 
	  End 
And Case Left(id,1)
			When 'F' Then ' QUOTA'
			When 'E' Then DescriptionF
			When 'D' Then DescriptionE
			When 'C' Then DescriptionD
			Else DescriptionC 
	  End like '%QUOTA'



  
