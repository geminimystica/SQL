
/*
--Some of my reference code for SQL.--
=====================================
-Code for my own reference. 
-Pretty awesome.
*/




--Send email to myself for long freaking queries - let you know when query is done.--
declare @subject varchar(100)
select @subject = 'SPID: ' + cast(@@SPID as varchar) + ' - Query Completed'
exec msdb.dbo.sp_send_dbmail @profile_name = 'MYEMAILSQL', @recipients = 'saturnBoov@gmail.com', @subject = @subject



/*^P searches carrige returns in MS Word. Neat.*/
--Interesting to not: ^p searches carrage returns in word.

/*Insert a picture in SQL.*/
insert into dbo.myImageTable
      (name,
       Picture)
select 'spaceAlien_11288', bulkcolumn
from OPENROWSET(BULK 'c:\uploadPictures\spaceAliens11288.jpg', SINGLE_BLOB) as Picture;



/*Another way to insert a picture into SQL.*/
INSERT INTO dbo.myImageTable values (1, (SELECT * FROM OPENROWSET(BULK N'C:\uploadPictures\thatWasaUFO1.png', SINGLE_BLOB) as T1))




--Search Recovery mode
SELECT name,recovery_model, recovery_model_desc, is_read_only  FROM master.sys.databases



--Dynamic USE statement - loop through dbs using stored procedure
DECLARE @command varchar(1000) 
SELECT @command = 'USE ? SELECT * FROM sys.database_principals' 
EXEC sp_MSforeachdb @command 





--Search databases, db files, their size, and drive name on a server - Researching disk drive growth.
USE master
SELECT sys.databases.name, sys.master_files.name, sys.master_files.physical_name, * 
FROM master.sys.master_files
JOIN sys.databases ON databases.database_id = master_files.database_id
WHERE sys.master_files.physical_name NOT LIKE  'model%'
ORDER BY sys.databases.name, sys.master_files.name



--Search databases, db files, their size, and drive name on a server - Researching disk drive growth.
USE spaceAliens
SELECT 
[db_name] = d.name, 
[table_name] = SCHEMA_NAME(o.[schema_id]) + '.' + o.name,
s.last_user_update, 
s.*
FROM sys.dm_db_index_usage_stats s
JOIN sys.databases d ON s.database_id = d.database_id
JOIN sys.objects o ON s.[object_id] = o.[object_id]
WHERE o.[type] = 'U'
AND s.last_user_update IS NOT NULL
AND s.last_user_update BETWEEN DATEADD(wk, -2, GETDATE()) AND GETDATE()
ORDER BY s.user_updates desc, s.last_user_update



--Search index user updates, seeks, scans, etc by date on database tables within a given database  - Researching disk drive growth.
USE spaceAliens
SELECT 
     SUM(s.user_updates) AS [Sum_User_Updates], 
	 [table_name] = SCHEMA_NAME(o.[schema_id]) + '.' + o.name 
FROM sys.dm_db_index_usage_stats s
JOIN sys.databases d ON s.database_id = d.database_id
JOIN sys.objects o ON s.[object_id] = o.[object_id]
WHERE o.[type] = 'U'
    AND s.last_user_update IS NOT NULL
    AND s.last_user_update BETWEEN DATEADD(wk, -1, GETDATE()) AND GETDATE()
	GROUP BY SCHEMA_NAME(o.[schema_id]) + '.' + o.name
	ORDER BY SUM(s.user_updates) desc, SCHEMA_NAME(o.[schema_id]) + '.' + o.name 


--Search total of index user updates by table on a database - Researching disk drive growth.
USE SpaceAliens
SELECT 
     SUM(s.user_updates) AS [Sum_User_Updates], [table_name] = SCHEMA_NAME(o.[schema_id]) + '.' + o.name 
FROM sys.dm_db_index_usage_stats s
JOIN sys.databases d ON s.database_id = d.database_id
JOIN sys.objects o ON s.[object_id] = o.[object_id]
WHERE o.[type] = 'U'
    AND s.last_user_update IS NOT NULL
    AND s.last_user_update BETWEEN DATEADD(wk, -1, GETDATE()) AND GETDATE()
	GROUP BY SCHEMA_NAME(o.[schema_id]) + '.' + o.name
	ORDER BY SUM(s.user_updates) desc, SCHEMA_NAME(o.[schema_id]) + '.' + o.name 



--Execute as login.
--Used execute as login to test the user permissions: 
USE SpaceAliens
EXECUTE AS login = 'UFO_Domain\gemi' 
EXEC [dbo].[myStoredProcedure] @aliensID = '887' 
SELECT * FROM dbo.aliensDoExist;



--connection tracking to a database
USE Admin; 
GO 
SELECT  TOP ( 100 ) * 
FROM   dbo.XE_ConnectionTracking_Log 
WHERE  DatabaseName = 'UFOFiles' 
ORDER BY LastConnection DESC; 




/*Script out a new database based off of an existing one.*/
/*In this use statement, we are going to select the UFO database to create a UFO_2021 one that is just like it but blank.*/
USE UFO
--create database script
SELECT 'CREATE DATABASE [ufo_' + '2021' + ']'+
'CONTAINMENT = NONE ON PRIMARY'
--List users and roles
select name AS [List Users]
from sys.database_principals
where sid is not null
and name != 'guest'
AND type_desc != 'DATABASE_ROLE'
order by name;
--list roles
select name AS [db Roles]
from sys.database_principals
where sid is not null
and name != 'guest'
AND type_desc = 'DATABASE_ROLE'
order by name;
--create user for login
SELECT  
'create user [' + dp.name + '] for login [' + sp.name  +'];' AS [Create User]
FROM   sys.database_principals AS DP
LEFT JOIN sys.server_principals AS SP
ON DP.sid = SP.sid
WHERE sp.name IS NOT NULL
AND dp.name != 'dbo'
ORDER BY dp.name;
--Create role members
select 'CREATE ROLE [' + name +'];' AS [create role]
from sys.database_principals
where sid is not null
and name != 'guest'
AND name != 'public'
AND type_desc = 'DATABASE_ROLE'
AND is_fixed_role != 1 --is not a built in role
order by name;
--List of members and roles associated with them.--
SELECT 
'alter role [' + rp.name + '] add member [' + mp.name  + '];' AS [Alter Role Add Member]
FROM sys.database_role_members rm
inner join sys.database_principals rp on rm.role_principal_id = rp.principal_id
inner join sys.database_principals mp on rm.member_principal_id = mp.principal_id
WHERE mp.name != 'dbo'
ORDER BY mp.name;
--permission
SELECT	CASE WHEN DBP.state <> 'W' THEN DBP.state_desc ELSE 'GRANT' END
+ SPACE(1) + DBP.permission_name + SPACE(1)
+ SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(USR.name) COLLATE database_default
+ CASE WHEN DBP.state <> 'W' THEN SPACE(0) ELSE SPACE(1) + 'WITH GRANT OPTION' END + ';' AS [permissions]
FROM	sys.database_permissions AS DBP
INNER JOIN	sys.database_principals AS USR	ON DBP.grantee_principal_id = USR.principal_id
WHERE	DBP.major_id = 0 and USR.name <> 'dbo'
AND USR.name <> 'public'
ORDER BY DBP.permission_name ASC, DBP.state_desc ASC
--number of columns in image table 2019
SELECT 
sys.tables.name, sys.columns.name AS [UFO 2021]
FROM sys.tables JOIN sys.columns ON columns.object_id = tables.object_id




/*Search SQL Server Agent jobs.*/
/*I like placing the search criteria in variables but this is a quick and easy way to perform it.*/
USE msdb
GO
SELECT 
Job.name AS JobName,
Job.enabled AS ActiveStatus,
JobStep.step_name AS JobStepName,
JobStep.command AS JobCommand
FROM   sysjobs Job
INNER JOIN sysjobsteps JobStep
ON Job.job_id = JobStep.job_id 
WHERE  JobStep.command LIKE '%ufo_2021%';





/*See if all jobs run on a certain day.*/
USE msdb
go
select 
j.name as 'JobName',
h.run_date,
h.run_time,
h.*
From msdb.dbo.sysjobs j 
INNER JOIN msdb.dbo.sysjobhistory h  ON j.job_id = h.job_id 
where j.enabled = 1
and run_date = '20210213'
AND j.name NOT IN ('ufo_story', 'Replication agents checkup', 'Distribution clean up: distribution')
order by j.name, h.run_date, h.run_time desc





/*Query the database compatibility Level.*/
select name, compatibility_level from sys.databases WHERE compatibility_level < 130;
/*Once you check it, you can script a db alter to increase the compatibility level if you find ones that are under.*/
SELECT 'ALTER DATABASE ' + name + ' SET COMPATIBILITY_LEVEL = 130;' FROM sys.databases WHERE compatibility_level < 130;
 


 
/*Create table with constraints by specified names.*/
USE ufo
CREATE TABLE [dbo].[ufo_categories](
	[ID] [INT] NOT NULL,
	[classification] INT NOT NULL,
	[classificationDescription] [VARCHAR](100) NOT NULL,
	[typeID] INT NOT NULL
 CONSTRAINT [PK_ufo_categories] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/*Just a constraint reference.*/
ALTER TABLE [dbo].ufo_categories WITH NOCHECK ADD  CONSTRAINT [FK_ufoType] FOREIGN KEY([typeID])
REFERENCES [dbo].[UFOType] ([typeID])
GO


/*Table creation reference - Identity.*/
USE UFO
CREATE TABLE [dbo].[ufo_2021](
	[ID] [INT] IDENTITY(1,1) NOT NULL,
	[serial] [INT] NOT NULL,
	[type] [INT] NOT NULL,
	[description] VARCHAR(120) NOT NULL,
	[DateEntered] [DATETIME] NOT NULL,
 CONSTRAINT [PK_ufo_2021] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO
/*Add a default constraint.*/
ALTER TABLE [dbo].[ufo_2021] ADD CONSTRAINT [DF_ufo_2021_DateEntered]  DEFAULT (getdate()) FOR [DateEntered]
GO



/*Select query text.*/
/*dm_exec_sql_text system table Returns the text of the SQL batch that is identified by the specified sql_handle. This table-valued function replaces the system function fn_get_sql.*/
SELECT dest.TEXT AS [Query],
queryStats.execution_count [Count],
queryStats.last_execution_time AS [Time]
FROM sys.dm_exec_query_stats AS queryStats
CROSS APPLY sys.dm_exec_sql_text(queryStats.sql_handle) AS dest
ORDER BY queryStats.last_execution_time DESC



/*
Logical over view for adding identity to an existing table and you do not want to mess with the data or 
reseed identity.
-	Create a new schema to hold the data
-	Transfer the table from the current schema to the holding schema
-	Build the table in the original schema with the identity property added
-	Build original clustered index
-	Transfer the table in the holding schema to the new table
-	Drop and create all triggers, constraints, foreign keys, indexes, etc. (the transfer will point them all to the table in the holding schema)
-	Drop the table from the holding schema
-	Drop the holding schema
*/




/*If Else for commit.*/
IF (SELECT name FROM msdb.dbo.sysjobs WHERE name LIKE '%UFO_Classification%') LIKE '%orange%' 
begin
BEGIN transaction
UPDATE ufo.dbo.jobTrack SET ignore = 1, ignore_reason = 'This is not setup for Tracking 3' WHERE trackName = 'UFO Classification - Tracking 3';
commit
END
ELSE 
begin
PRINT 'THIS PROCESS FAILED'
end







/*Query the jobs that just executed and list the time they did it.*/
/*The where clause can also specify a job that executed but does not have a stop execution date.*/
use msdb
go
SELECT
    ja.job_id,
    j.name AS job_name,
    ja.start_execution_date,
	ja.stop_execution_date,
    ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id,
    Js.step_name,
	ja.session_id
FROM msdb.dbo.sysjobactivity ja 
LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id 
--AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
WHERE start_execution_date is not null
AND stop_execution_date is null;







/*Not SQL - More just Excel notes.*/
/*
This is how to make comparisons using excel for FINDING DUPLICATES.
Note: Still easier to do in a SQL Database but this is here. Whatever.

-1: combine all columns into a new one.
Formula:
=A2&B2&C2&D2
-2: Create another column. This will be a comparison column that will let you know if the value within the combination column has duplicate information or Original information.
Formula:
=IF(COUNTIF($K$2:K2,K2)>1, "Here I am! I'm a duplicate!","Original")
*/







/*Tracking down restarts.*/
/*This is actually powershell code but really useful for general server stuff.*/
/*
/*POWERSHELL*/  
      Get-EventLog System -Newest 10000 | `
        Where EventId -in 41,1074,1076,6005,6006,6008,6009,6013 | `
        Format-Table TimeGenerated,EventId,UserName,Message -AutoSize -wrap
       
/*Event ID's.*/
these are the codes, you can add or remove them depending on what your are looking for:
Event ID     Description
41     The system has rebooted without cleanly shutting down first.
1074     The system has been shutdown properly by a user or process.
1076     Follows after Event ID 6008 and means that the first user with shutdown privileges logged on to the server after an unexpected restart or shutdown and specified the cause.
6005     The Event Log service was started. Indicates the system startup.
6006     The Event Log service was stopped. Indicates the proper system shutdown.
6008     The previous system shutdown was unexpected.
6009     The operating system version detected at the system startup.
6013     The system uptime in seconds.
*/







/*Just some date junk.*/
/*This is to dynamically determine the Start, Last Day, First Day, and times for next year.*/
/*I find this interesting.*/
SELECT
DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0) AS StartOfYear,
DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) + 1, -1) AS LastDayOfYear,
DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) + 1, 0) AS FirstOfNextYear,
DATEADD(ms, -3, DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) + 1, 0)) AS LastTimeOfYear,
DATEADD(ms, -3, DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) + 2, 0)) AS LastTimeOfNextYear
SELECT DATEADD(yy, 1, DATEADD(DAY, 1 - DATEPART(DAYOFYEAR, GETDATE()), CAST(GETDATE() AS DATE)))  AS nextyear
SELECT DATEADD(yy, 2, DATEADD(DAY, 1 - DATEPART(DAYOFYEAR, GETDATE()), CAST(GETDATE() AS DATE)))  AS twoYears



/*Search database users and list information from db_principals.*/
USE UFO
SELECT
DB_NAME() AS [database],
account.name AS AccountName,
account.type AS AccountType,
account.type_desc AS AccountDesc,
permission.name,
serv.is_disabled,
serv.name AS loginName
FROM sys.database_role_members AS roles  
JOIN sys.database_principals AS permission ON roles.role_principal_id = permission.principal_id  
JOIN sys.database_principals AS account ON roles.member_principal_id = account.principal_id
LEFT JOIN sys.server_principals AS serv ON serv.sid = account.sid
WHERE 
account.name <> '%dbo%'
AND account.name LIKE '%gemigemi%'
ORDER BY account.name;







/*Using Substring and CharIndex.*/
/*This is used to get a set of text from a bunch of text.*/

/*An Example of using Substring and PATINDEX to extract Numbers out of a set of text and display them as seperate data.*/
DECLARE
@aThing VARCHAR(50) = 'spaceAliensTeam888'
select
rtrim(substring(@aThing, 1, PATINDEX('%[0-9]%', @aThing) -1)) Team,
ltrim(rtrim(substring(@aThing, PATINDEX('%[0-9]%', @aThing), 3))) TeamNumber;




/*Concept:: If your data is found to have any sort of patern as to when your desired text starts and ends, then use Substring and charindex to extract the text you want.*/
DECLARE 
@Text VARCHAR(1000) = 'This is a set of text - I have a collection of ufos.;. Data 1 - the expression states to go South, East, North, then West and end up right at your starting location because you need to only travel in box formation. Fish are a hoax.',
@First VARCHAR(2) = '- ',
@Second VARCHAR(2) = ';.'
SELECT SUBSTRING(@Text, CHARINDEX(@First, @Text) + LEN(@First), 
CHARINDEX(@Second, @Text) - CHARINDEX(@First, @Text) - LEN(@First));





/*Query Subscriptions within the ReportServer (SSRS Default) in SQL Server.*/
/*
-Usually, you will browse to your web prortal in SQL Server Reporting Services, click on your report, and go use the Manage to look at the it's subscription.
-Much of the time, you need to peer at each individual subscription for each individual Report.
-This is a way to view them all together in SQL.
-Connect to your report server and use the ReportServer database.
-For this scenario, we are querying the Catalog, the subscriptions, the dataSource, users, ReportSchedule, and Schedule tables.
-This is a handy query if you want to look at when report subcriptions were run last and what the last status was.
*/
USE ReportServer
go
SELECT c.Name
, c.Type
, c.Description
, u.UserName AS CreatedBy
, c.CreationDate
, c.ModifiedDate
, s.Description AS Subscription
, s.DeliveryExtension AS SubscriptionDelivery
, d.Name AS DataSource
, s.LastStatus
, s.LastRunTime
, s.Parameters
, sch.StartDate AS ScheduleStarted
, sch.LastRunTime AS LastSubRun
, sch.NextRunTime
, c.Path
FROM Catalog c
INNER JOIN Subscriptions s ON c.ItemID = s.Report_OID
INNER JOIN DataSource d ON c.ItemID = d.ItemID
LEFT OUTER JOIN Users u ON u.UserID = c.CreatedByID
LEFT OUTER JOIN ReportSchedule rs ON c.ItemID = rs.ReportID
LEFT OUTER JOIN Schedule sch ON rs.ScheduleID = sch.ScheduleID







/*Row Count Performed Through System Tables.*/
/*Use: This is absolutely great for large tables that can take a long time to get the count from. Finishes in seconds comparitively.*/
/*This process is especially useful for obtaining the table count quickly.*/
/*Specify a table.*/
use UFO;
GO
DECLARE @TableName sysname
SET @TableName = 'ufo_2021'
SELECT TBL.object_id, TBL.name, SUM(PART.rows) AS rows
FROM sys.tables TBL
INNER JOIN sys.partitions PART ON TBL.object_id = PART.object_id
INNER JOIN sys.indexes IDX ON PART.object_id = IDX.object_id
AND PART.index_id = IDX.index_id
WHERE TBL.name = @TableName
AND IDX.index_id < 2
GROUP BY TBL.object_id, TBL.name;




/*SQL Example - Run Powershell Scripts in SQL.*/
USE [Admin]
GO
/*Declare variables.*/
DECLARE 
@SQL VARCHAR(MAX),
@LocalScriptPath VARCHAR(100),
@myFile varchar(100),
@myFile2 VARCHAR(100);
/*Set Variables.*/
SELECT @LocalScriptPath	= 'C:\thoseScripts\'
SELECT @myPSFile1 = 'runPowershell_findUsers.ps1 '
SELECT @myPSFile2 = 'powershellRunSearch.ps1 '
/*Set SQL variable including the powrshell run setup.*/
SELECT @SQL = 'xp_cmdshell ''powershell.exe ' + @LocalScriptPath + @myPSFile2
	+ @@servername + ' ' -- Source
	+ @@servername + ''''; -- Destination
/*Display what it's doing.*/
	PRINT '-- Run Lookup powershell scripts.';
	PRINT @SQL;
	PRINT '';
/*Execute the script.*/
BEGIN
	EXEC(@SQL);
END;



/*Lookup AG Information.*/
select 
*
from sys.availability_databases_cluster as dbClust
inner join sys.availability_replicas as ARep
on dbClust.group_id = ARep.group_id
inner join sys.dm_hadr_availability_replica_states as replicaStates on ARep.replica_id = replicaStates.replica_id
where ARep.replica_server_name = @@SERVERNAME
and replicaStates.role_desc <> 'PRIMARY'


/*More AG health lookups.*/

SELECT
    dbClust.database_name,
    replicaState.synchronization_health_desc,
    replicaState.synchronization_state_desc,
    replicaState.database_state_desc
FROM
    sys.dm_hadr_database_replica_states replicaState
    JOIN sys.availability_databases_cluster dbClust ON replicaState.group_database_id = dbClust.group_database_id
    AND replicaState.is_local = 1





/*Memory checks.*/
SELECT  *
FROM    sys.dm_os_memory_clerks
ORDER   BY pages_kb DESC



/*Memory Consumer.*/
SELECT memory_consumer_desc  
, allocated_bytes/1024 AS allocated_bytes_kb  
, used_bytes/1024 AS used_bytes_kb  
, allocation_count  
FROM sys.dm_xtp_system_memory_consumers  
SELECT memory_object_address  
, pages_in_bytes  
, bytes_used  
, type  
FROM sys.dm_os_memory_objects WHERE type LIKE '%xtp%'  
/*Memory.*/
SELECT type  
, name  
, memory_node_id  
, pages_kb/1024 AS pages_MB   
FROM sys.dm_os_memory_clerks WHERE type LIKE '%xtp%'  




/*Get Total DB Size in SQL.*/
USE spaceAliens
SELECT SUM(size)/128 AS [Total database size (MB)]
FROM tempdb.sys.database_files



/*Search indexes.*/
USE master
select 
avg_fragmentation_in_percent, 
page_count, 
fragment_count
FROM master.sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED');





/*Lookup database users.*/
SELECT * FROM sys.database_principals;
/*Searching for specified SQL Logins on ALL Servers.*/
SELECT name FROM sys.server_principals WHERE name LIKE '%gemigemi%';
/*Searching for specified SQL Logins on ALL Databases on ALL Servers.*/
EXEC sys.sp_MSforeachdb @command1 = N'use [?];select db_name(db_id()), name from sys.database_principals WHERE name like ''%gemigemi%'''




/*FIX Index Defrag issues.*/
alter index pk_myUFOTable on [myDB].[dbo].[myTable] REORGANIZE;
update statistics [myDB].[dbo].[myTable] pk_myUFOTable;
update statistics [myDB].[dbo].[myTable] WITH FULLSCAN;


/*Use the Informatino schema to look up constraint names.*/
USE spaceAliens
SELECT *
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE CONSTRAINT_NAME LIKE '%PK__%'
AND table_name = '%event%'



/*Query this list to see what databases are marked as Accessible.*/
SELECT
dtb.name AS [Name],
dtb.database_id AS [ID],
CAST(HAS_DBACCESS(dtb.name) AS BIT) AS [IsAccessible]
FROM
master.sys.databases AS dtb
ORDER BY
[Name] ASC;



/*Estimated Completion Time for a Query.*/
SELECT session_id AS SPID, command, a.text AS Query, start_time, percent_complete,
DATEADD(SECOND,estimated_completion_time/1000, GETDATE()) AS estimated_completion_time
FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a;




/*Query filename paths on a server.*/
SELECT name, physical_name
FROM MASTER.SYS.MASTER_FILES
WHERE database_id = DB_ID('UFO_2021');




/*Query for rebuilding an index.*/
USE spaceAliens
GO
ALTER INDEX [IX_myindex] ON [dbo].[ufo_2021] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO



/*Additional AG Queries:*/
/*Query Availability Groups on all servers.*/
/*Meant to be run in distributed query (entire environment).*/
SELECT Groups.[Name] AS AGname, 
*
FROM sys.dm_hadr_availability_group_states States
INNER JOIN master.sys.availability_groups Groups ON States.group_id = Groups.group_id;

/*Query Availability groups on all servers - more information about clusters.*/
/*Meant to be run in distributed query (entire environment).*/
SELECT
Groups.[Name] AS AGname,
AGDatabases.database_name AS Databasename,
*
FROM sys.dm_hadr_availability_group_states States
INNER JOIN master.sys.availability_groups Groups ON States.group_id = Groups.group_id
INNER JOIN sys.availability_databases_cluster AGDatabases ON Groups.group_id = AGDatabases.group_id
ORDER BY
AGname ASC,
Databasename ASC;




/*Insert Update that is surrounded in a transaction. This also tracks them in TranCount.*/
USE UFO
begin
/*Drop temp table if it exists.*/
DROP TABLE IF EXISTS #ufoTeam2;
/*Create temp table.*/
CREATE TABLE #ufoTeam2
(myID INT,
member VARCHAR(200),
category INT);
/*Get the count.*/
DECLARE @count INT;
SET @count = (SELECT COUNT(*) FROM #ufoTeam2)
/*Setup the transaction for inserting data. This is included in a tryCatch.*/
BEGIN try
BEGIN TRANSACTION
    If  (@count = 0)
	begin
		Insert Into #ufoTeam2
					(
						myID,
						member,
						category
					)
		SELECT id, people, setup FROM dbo.allPeople WHERE scout = 1 AND securityLevel = 6;
			End
		else
			Begin
				Update #ufoTeam2 set category = 5 WHERE myID = 2
			End
		set nocount OFF            
END TRY
	BEGIN CATCH			
	IF @@TRANCOUNT > 0  
		PRINT 'Rolling back'; 
		ROLLBACK TRANSACTION; 						
		THROW;
	END CATCH;
	IF @@TRANCOUNT > 0
		COMMIT TRANSACTION;
END;
DROP TABLE #ufoTeam2;
GO


/*Alternative catch for a transaction.*/
	BEGIN CATCH
		ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
		IF @@TRANCOUNT > 0
            COMMIT TRANSACTION;
    END;
    DROP TABLE #ufoTeam2;
END;
GO









/*Delete in chunks - This example is useful when performing deletes on a high availability table.*/
USE ufo
GO
DECLARE @RowCount BIGINT;
DECLARE @start INT;
DECLARE @end INT;
DECLARE @RowsUpdated INT;
DECLARE @TotalRowsUpDated INT;
DECLARE @MaxDate DATETIME;

SET @MaxDate = DATEADD(MONTH, -9, GETDATE())
SET @TotalRowsUpDated = 0;
SET @RowsUpdated = 0;
SET @start = 0;
SET @end = 0;

SELECT @RowCount = COUNT_BIG(1) FROM dbo.largeTable AS lg WITH (NOLOCK) WHERE lg.validDate < @MaxDate

WHILE @end < @RowCount
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        SET @end = @start + 1000000;
        DELETE FROM dbo.largeTable WHERE validDate IN
		(select TOP (1000000) lg.validDate FROM dbo.largeTable as lg WHERE lg.validDate < @MaxDate ORDER BY lg.validDate)

        SET @RowsUpdated = @@ROWCOUNT;
        SET @TotalRowsUpDated = @TotalRowsUpDated + @RowsUpdated;
		SET @start = @end + 1;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    IF @@TRANCOUNT > 0
        COMMIT TRANSACTION;
    PRINT @RowsUpdated;
    WAITFOR DELAY '00:00:05';
END;
PRINT @TotalRowsUpDated;
SELECT @@TRANCOUNT





/*
-Script Generator for Shrinking Database Logs-
===============================================

-Generate script from master_files and databases tables to Shrink Logs for All DB's on a server.

-Criteria includes the disk that wea re usually looking in, as well as the type being a log file. 
-We do not shrink data files such as mdfs and ndfs.
-We only get the ldf files that are specified in the physical_name, but they will always be set
as LOG file in the type_desc column.
-Most servers have ther log files stored in the L drive, but some have additional log files on other 
drives such as K. The second script below will show you log files that exist on another drive. Change
the K to the drive letter you need.
-The Script is designed to always specify LOG for the files so that we are only shrinking .ldf files.
-Excludes read-only databases.
*/
USE master
GO

--Generate Shrink Scripts for the L Drive.
SELECT 'USE [' + d.name + '] DBCC SHRINKFILE (N''' + f.name  + ''' ,0, TRUNCATEONLY)' 
FROM sys.master_files f
JOIN sys.databases d ON d.database_id = f.database_id
WHERE f.type_desc = 'LOG' AND f.physical_name LIKE 'L%'
AND d.is_read_only =0;

--Generate Shrink Scripts for .ldf files on Another Drive (specify K, M, U, etc. Usually will be K.)
SELECT 'USE [' + d.name + '] DBCC SHRINKFILE (N''' + f.name  + ''' ,0, TRUNCATEONLY)' 
FROM sys.master_files f
JOIN sys.databases d ON d.database_id = f.database_id
WHERE f.type_desc = 'LOG' AND f.physical_name LIKE 'D%'
AND d.is_read_only =0;





/*Generate alter script for databases that are in full Recovery Mode.*/
SELECT 'ALTER DATABASE [' + [name] + '] SET RECOVERY SIMPLE WITH NO_WAIT;'
FROM sys.databases WHERE recovery_model_desc = 'FULL';





--Search sysprocesses for blocking.
SELECT * FROM sys.sysprocesses WHERE blocked > 0
--search by spid
SELECT * FROM sys.sysprocesses WHERE spid = 280;




/*Search blocking by table locks.*/
use ufo
go
select COALESCE(O.name,PO.name) as ObjectName
    , COALESCE(O.type_desc,PO.type_desc) as ObjectTypeDesc
    , T.request_session_id
    , T.resource_database_id
    , T.resource_associated_entity_id
    , T.resource_description
    , T.request_mode
    , T.request_type
    , T.request_status
    , T.request_lifetime
    , T.request_owner_type
from sys.dm_tran_locks as T
left outer join sys.objects as O on T.resource_associated_entity_id = O.object_id
left outer join sys.partitions as P on T.resource_associated_entity_id = P.hobt_id
left outer join sys.objects as PO on P.object_id = PO.object_id
where T.resource_database_id = DB_ID() and T.resource_type not in ('DATABASE','METADATA');




