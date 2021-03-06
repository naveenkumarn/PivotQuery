USE [TestDb]
GO
/****** Object:  StoredProcedure [dbo].[Pivotpr]    Script Date: 02-06-2018 00:41:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER Proc [dbo].[Pivotpr](@Fromdate datetime, @Todate DateTime)

AS
SET NOCOUNT ON

DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)
 /*
 DECLARE @PivotSalesData Table 
 (
 [Date] NVarchar(max),
 [Hour] Nvarchar(max),
 [Sales count] int
  )
  --select * from @PivotSalesData
INSERT INTO @PivotSalesData
SELECT CAST(CAST(shippeddate AS DATE) AS Varchar(max)) [Date], 
   DATEPART(hour,shippeddate) [Hour], Count(1)  [Sales Count]  
FROM Ordershipped 
Where shippeddate Between @Fromdate AND @Todate
GROUP BY CAST(shippeddate AS DATE), DATEPART(hour,shippeddate)
*/

--IF  EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id
--    WHERE st.name = N'TableType' AND ss.name = N'dbo')
--    begin
--    drop type dbo.TableType
--    end
--    create type dbo.TableType as table([Date] varchar(max), [Hour] int, [Sales Count] int)
--    go 

declare @TempTable as dbo.TableType;

INSERT INTO @TempTable
SELECT CAST(CAST(shippeddate AS DATE) AS Varchar(max)) [Date], 
   DATEPART(hour,shippeddate) [Hour],
   Count(1)  [Sales Count]   
FROM Ordershipped
Where shippeddate Between @Fromdate AND @Todate
GROUP BY CAST(shippeddate AS DATE), DATEPART(hour,shippeddate)

INSERT INTO @TempTable
SELECT CAST(CAST(shippeddate AS DATE) AS Varchar(max))+'-RT' [Date], 
   DATEPART(hour,shippeddate) [Hour],
    SUM(count(1)) over(Partition by CAST(CAST(shippeddate AS DATE) AS Varchar(max)) order by DATEPART(hour,shippeddate))
   --Count(1)  [Sales Count]   
FROM Ordershipped
Where shippeddate Between @Fromdate AND @Todate
GROUP BY CAST(shippeddate AS DATE), DATEPART(hour,shippeddate)


SELECT * FROM @TempTable


--Get distinct values of the PIVOT Column 
SELECT @ColumnName= ISNULL(@ColumnName + ',','') 
       + QUOTENAME([Date])
FROM (SELECT DISTINCT [Date] FROM @TempTable) AS Dates
--Prepare the PIVOT query using the dynamic 
SET @DynamicPivotQuery = 
  N'SELECT [Hour], ' + @ColumnName + '
    FROM @TempTable
    PIVOT(SUM( [Sales Count]   ) 
          FOR [Date] IN (' + @ColumnName + ')) AS PVTTable'

----Execute the Dynamic Pivot Query
exec sp_executesql @DynamicPivotQuery,N'@TempTable dbo.TableType READONLY', @TempTable;



--SELECT * FROM #PivotSalesData
--DROP TABLE #PivotSalesData

 --EXec  Pivotpr '2018-05-27','2018-05-30'


