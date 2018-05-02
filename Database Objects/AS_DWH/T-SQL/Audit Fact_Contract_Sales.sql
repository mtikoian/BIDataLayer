-- Audit Fact_Contract_Sales

Declare @StartDate date,
	    @scube_Count int,
		@ccube_Count int

Select @StartDate = YearFirstDate
from as_dwh.dbo.timemaster
Where actualdate = Cast(dateadd(year,-2,Getdate()) as Date)

Select @scube_Count = Count(*)
from AS_dwh.edw.fact_Sales_Order f
Left Join as_dwh.dbo.timemaster cd
on f.[Dim_COMM_SALES_KEY] = cd. dayid 
Where cd.ActualDate >= @StartDate

Select @ccube_Count = Count(*)
from as_dwh.edw.Fact_Contract_Sales

Print 'Sales Cube Rows     = ' + convert(varchar,@scube_Count) 
Print 'Contracts Cube Rows = ' + convert(varchar,@ccube_Count) 

if  @scube_Count <> @ccube_Count
	begin
	print ' Audit Error: Sales Row Count <> Contracts Cube Row Count '  
	raiserror ( 'Sales Row Count <> Contracts Cube Row Count ',15,1)
	print ' '
	End

Select Dim_Ship_to_Customer_location_Key, Hospital_Name, IDN, Definitive_ID
from as_dwh.edw.Dim_Contract_Customer c
Where Dim_Ship_to_Customer_location_Key in 
	(Select Dim_Ship_to_Customer_location_Key
	from as_dwh.edw.Dim_Contract_Customer c
	group by Dim_Ship_to_Customer_location_Key
	Having Count(*) > 1)


