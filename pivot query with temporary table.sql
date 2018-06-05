
Create Procedure Pivotproc(@Fromdate datetime,@Todate datetime)

AS
SET NOCOUNT ON

declare @dynamicpivotquery nvarchar(max)

declare @columnname nvarchar(max)

--declare @fromdate datetime 
--declare @todate datetime 

--set @fromdate ='2018-05-27'
--set @todate = '2018-05-30'

declare @temphours table (hour int)
declare @totalhours table (date varchar(max),hour int,ordercount int)

declare @temptable as dbo.tabletype
declare @sampletable as dbo.tabletype

insert into @temphours
select 0 union all
select 1 union all
select 2 union all
select 3 union all
select 4 union all
select 5 union all
select 6 union all
select 7 union all
select 8 union all
select 9 union all
select 10 union all
select 11 union all
select 12 union all
select 13 union all
select 14 union all
select 15 union all
select 16 union all
select 17 union all
select 18 union all
select 19 union all
select 20 union all
select 21 union all
select 22 union all
select 23 


;with daterange (datedata) as 
(
select @fromdate as [date] union all
select dateadd(d,1,datedata) from daterange where datedata<@todate
)

insert into @totalhours
select cast(cast([datedata] as date) as varchar(max)) ,
       hour ,0
	   from daterange cross apply @temphours

/*
	  insert into @temptable 
	  select 
	  cast(CAST(shippeddate as date) as varchar(max)) [date],
	  datepart(hour,shippeddate) [hour],
	  count(1) 
      from Ordershipped 
	  where shippeddate between @fromdate and @todate 
	  group by 
	   cast(CAST(shippeddate as date) as varchar(max)),
	  datepart(hour,shippeddate)


	  */




	  	  select 
	  cast(CAST(shippeddate as date) as varchar(max)) [date],
	  datepart(hour,shippeddate) [hour],
	  count(1) AS ordercount into #temptable
	  from Ordershipped 
	  where shippeddate between @fromdate and @todate 
	  group by 
	   cast(CAST(shippeddate as date) as varchar(max)),
	  datepart(hour,shippeddate)





	  /*
	  insert into @temptable 
	  select 
	  o.date [date],
	  o.hour [hour],0
	  from @totalhours as o left join @temptable as a on o.date=a.Date and o.hour=a.hour
	  where a.Date is null and a.Hour is null 

	  */


	  
	  insert into #temptable 
	  select 
	  o.date [date],
	  o.hour [hour],0 as ordercount
	  from @totalhours as o left join #temptable as a on o.date=a.Date and o.hour=a.hour
	  where a.Date is null and a.Hour is null 

/*
	  insert into @sampletable
	  select * from @temptable
*/
select * into #sampletable
	   from #temptable
/*
	  insert into @temptable
	  select 
	  [date]+'-RT'  [date],
      hour [hour],
	  sum([sales count]) over (partition by [date] order by [hour]) 
	  from @sampletable
*/


	  insert into #temptable
	  select 
	  cast([date] as varchar(max))+'-RT'  [date],
      hour [hour],
	  sum([ordercount]) over (partition by [date] order by [hour]) 
	  from #sampletable



	  --Get distinct values of the PIVOT Column 
SELECT @ColumnName= ISNULL(@ColumnName + ',','') 
       + QUOTENAME([Date])
FROM (SELECT DISTINCT [Date] FROM #temptable) AS Dates
--Prepare the PIVOT query using the dynamic 
SET @DynamicPivotQuery = 
  N'SELECT 
  
		CASE WHEN [Hour] = 0 THEN ''12:00 AM''
			 WHEN [Hour] < 12 THEN cast([Hour] as varchar(max)) + '':00 AM''
			 WHEN [Hour] = 12 THEN ''12:00 PM''
			 ELSE cast( ([Hour] % 12) as varchar(max)) + '':00 PM''
		END [Hour]
	, ' + @ColumnName + '
    FROM #TempTable
    PIVOT(SUM( [ordercount]   ) 
          FOR [Date] IN (' + @ColumnName + ')) AS PVTTable'

----Execute the Dynamic Pivot Query
exec sp_executesql @DynamicPivotQuery

--,N'@TempTable dbo.TableType READONLY', @TempTable;

drop table #temptable
drop table #sampletable



--Exec  Pivotproc '2018-05-27','2018-05-30'