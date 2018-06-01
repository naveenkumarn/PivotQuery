DECLARE @Fromdate datetime, @Todate DateTime

DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)

SET @Fromdate = '2018-05-27'
SET @Todate = '2018-05-30';

DECLARE @TempHours Table (Hour INT)

declare @TempTable as dbo.TableType;

declare @SampleTable as dbo.TableType;

DECLARE @TotalHours table([Date] varchar(max), [Hour] int, [Sales Count] int)

INSERT INTO @TempHours
	SELECT 0 UNION ALL
	SELECT 1 UNION ALL
	SELECT 2 UNION ALL
	SELECT 3 UNION ALL
	SELECT 4 UNION ALL
	SELECT 5 UNION ALL
	SELECT 6 UNION ALL
	SELECT 7 UNION ALL
	SELECT 8 UNION ALL
	SELECT 9 UNION ALL
	SELECT 10 UNION ALL
	SELECT 11 UNION ALL
	SELECT 12 UNION ALL
	SELECT 13 UNION ALL
	SELECT 14 UNION ALL
	SELECT 15 UNION ALL
	SELECT 16 UNION ALL
	SELECT 17 UNION ALL
	SELECT 18 UNION ALL
	SELECT 19 UNION ALL
	SELECT 20 UNION ALL
	SELECT 21 UNION ALL
	SELECT 22 UNION ALL
	SELECT 23 ;


WITH DateRange(DateData) AS 
(
    SELECT @Fromdate as Date
    UNION ALL
    SELECT DATEADD(d,1,DateData)
    FROM DateRange 
    WHERE DateData < @Todate
)

INSERT INTO @TotalHours
SELECT CAST(CAST(DateData AS DATE) AS Varchar(max)),[Hour],0
FROM DateRange
CROSS APPLY @TempHours




INSERT INTO @TempTable
SELECT CAST(CAST(shippeddate AS DATE) AS Varchar(max)) [Date], 
   DATEPART(hour,shippeddate) [Hour],
   Count(1)  [Sales Count]   
FROM dbo.Ordershipped
Where shippeddate Between @Fromdate AND @Todate
GROUP BY CAST(shippeddate AS DATE), DATEPART(hour,shippeddate)


INSERT INTO @TempTable
	SELECT O.Date,O.Hour,0
		FROM @TotalHours AS O
		LEFT JOIN @TempTable AS A ON O.Date = A.Date AND A.Hour = O.Hour
		WHERE A.Date IS NULL AND A.Hour IS NULL


INSERT INTO @SampleTable
	SELECT * FROM @TempTable

INSERT INTO @TempTable
SELECT [Date]+'-RT' [Date], 
   [Hour] [Hour],
    SUM([Sales Count]) over(Partition by [Date] order by [Hour])
   --Count(1)  [Sales Count]   
FROM @SampleTable


--Get distinct values of the PIVOT Column 
SELECT @ColumnName= ISNULL(@ColumnName + ',','') 
       + QUOTENAME([Date])
FROM (SELECT DISTINCT [Date] FROM @TempTable) AS Dates
--Prepare the PIVOT query using the dynamic 
SET @DynamicPivotQuery = 
  N'SELECT 
  
		CASE WHEN [Hour] = 0 THEN ''12:00 AM''
			 WHEN [Hour] < 12 THEN cast([Hour] as varchar(max)) + '':00 AM''
			 WHEN [Hour] = 12 THEN ''12:00 PM''
			 ELSE cast( ([Hour] % 12) as varchar(max)) + '':00 PM''
		END [Hour]
	, ' + @ColumnName + '
    FROM @TempTable
    PIVOT(SUM( [Sales Count]   ) 
          FOR [Date] IN (' + @ColumnName + ')) AS PVTTable'

----Execute the Dynamic Pivot Query
exec sp_executesql @DynamicPivotQuery,N'@TempTable dbo.TableType READONLY', @TempTable;