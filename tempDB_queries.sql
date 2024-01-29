
/*TempDB*/
/*
-Monitoring Goals:
1: free space.
2: Used space.
3: Total space.
4: Percentage of used space: 
5: total disk space
*/



USE tempdb
/*system proc.*/
/*The proc result set has a certain order to the columns. @OneResultSet is set to 1 to flatten the data retrieved so it can be inserted into the table.*/
EXEC sys.sp_spaceused @oneresultset = 1;


/*TempDB - View size configurations.*/
USE tempdb
 SELECT name AS FileName,
    size*1.0/128 AS FileSizeInMB,
    CASE max_size
        WHEN 0 THEN 'Autogrowth is off.'
        WHEN -1 THEN 'Autogrowth is on.'
        ELSE 'Log file grows to a maximum size of 2 TB.'
    END,
    growth AS 'GrowthValue',
    'GrowthIncrement' =
        CASE
            WHEN growth = 0 THEN 'Size is fixed.'
            WHEN growth > 0 AND is_percent_growth = 0
                THEN 'Growth value is in 8-KB pages.'
            ELSE 'Growth value is a percentage.'
        END
FROM tempdb.sys.database_files;
GO




/*Sum of Free space and free pages.*/
SELECT 
(SUM(unallocated_extent_page_count) * 1.0 / 128) AS [free_space_MB],
(SUM(version_store_reserved_page_count) * 1.0 / 128) AS [version_space_used_MB],
(SUM(internal_object_reserved_page_count) * 1.0 / 128) AS [internal_object_space_used_MB],
(SUM(user_object_reserved_page_count) * 1.0 / 128) AS [user_object_space_MB],
SUM(unallocated_extent_page_count) AS [free_pages],
SUM(version_store_reserved_page_count) AS [version_pages_used],
SUM(internal_object_reserved_page_count) AS [internal_object_pages_used],
SUM(user_object_reserved_page_count) AS [user object pages used]

FROM sys.dm_db_file_space_usage;
GO




/*Transaction query :: Database Transactions Joined with Session Transactions.*/
/*Result: Aggragate on how much space a transactions is using by a single session ID. Grouped by Session_Id.*/
/*Where clause is set to specify the TempDB. Tempdb is always database_id 2.*/
USE tempdb
go
SELECT 
sessionTran.session_id, 
SUM(dbTran.database_transaction_log_bytes_reserved) AS database_transaction_log_byptes_reserved_TOTAL
FROM sys.dm_tran_database_transactions AS dbTran 
INNER JOIN sys.dm_tran_session_transactions AS sessionTran
ON dbTran.transaction_id = sessionTran.transaction_id 
WHERE dbTran.database_id = 2
GROUP BY 
sessionTran.session_id;




/*Query the page space consumed by Page Count.*/
SELECT
SUM (user_object_reserved_page_count)*8 as user_object_pageCount_in_kb,
SUM (internal_object_reserved_page_count)*8 as internal_obj_pageCount_kb,
SUM (version_store_reserved_page_count)*8  as version_store_pageCount_kb,
SUM (unallocated_extent_page_count)*8 as freespace_pageCount_kb,
SUM (mixed_extent_page_count)*8 as mixedextent_pageCount_kb
FROM sys.dm_db_file_space_usage




/*Query the page space consumed by internal objects in all currently running tasks in each session.*/
/*Page space query by session.*/
/*Multi row.*/
SELECT session_id,
    SUM(internal_objects_alloc_page_count) AS NumOfPagesAllocatedInTempDBforInternalTask,
    SUM(internal_objects_dealloc_page_count) AS NumOfPagesDellocatedInTempDBforInternalTask,
    SUM(user_objects_alloc_page_count) AS NumOfPagesAllocatedInTempDBforUserTask,
    SUM(user_objects_dealloc_page_count) AS NumOfPagesDellocatedInTempDBforUserTask
FROM sys.dm_db_task_space_usage
GROUP BY session_id
ORDER BY NumOfPagesAllocatedInTempDBforInternalTask DESC, NumOfPagesAllocatedInTempDBforUserTask DESC



/*Query the page space consumed by internal objects in the current session for both running tasks in each session.*/
/*Page space query by session.*/
/*Multi row.*/
SELECT R2.session_id,
  R1.internal_objects_alloc_page_count
  + SUM(R2.internal_objects_alloc_page_count) AS session_internal_objects_alloc_page_count,
  R1.internal_objects_dealloc_page_count
  + SUM(R2.internal_objects_dealloc_page_count) AS session_internal_objects_dealloc_page_count
FROM sys.dm_db_session_space_usage AS R1
INNER JOIN sys.dm_db_task_space_usage AS R2 ON R1.session_id = R2.session_id
GROUP BY R2.session_id, R1.internal_objects_alloc_page_count,
  R1.internal_objects_dealloc_page_count;


/*Query that captures SQL. Can also be modified to specify sessions.*/
SELECT 
R1.session_id, 
R1.request_id, 
R1.internal_objects_alloc_page_count, 
R1.internal_objects_dealloc_page_count,
R1.user_objects_alloc_page_count,
R1.user_objects_dealloc_page_count,
R3.internal_objects_alloc_page_count ,
R3.internal_objects_dealloc_page_count,
R3.user_objects_alloc_page_count,
R3.user_objects_dealloc_page_count,
R2.sql_handle, 
RL2.text as SQLText, 
R2.statement_start_offset, 
R2.statement_end_offset, 
R2.plan_handle
FROM sys.dm_db_task_space_usage 
R1 
INNER JOIN 
sys.dm_db_Session_space_usage R3 
ON R1.session_id = R3.session_id 
left outer JOIN sys.dm_exec_requests R2 ON R1.session_id = R2.session_id and R1.request_id = R2.request_id
OUTER APPLY sys.dm_exec_sql_text(R2.sql_handle) AS RL2
WHERE
RL2.text IS NOT NULL
ORDER BY R1.session_id;






/*
--Microsoft Provided Queries - Simple Structure for Reference.--
*/

/*Query the amount of Free Space in tempdb.*/
/*Microsoft provided query.*/
SELECT SUM(unallocated_extent_page_count) AS [free pages],
 (SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM tempdb.sys.dm_db_file_space_usage;

/*Query the amount of free space used by the version store.*/
/*Microsoft provided query.*/
SELECT SUM(version_store_reserved_page_count) AS [version store pages used],
  (SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
FROM tempdb.sys.dm_db_file_space_usage;

/*Query the amount of space used by internal objects.*/
/*Microsoft provided query.*/
SELECT SUM(internal_object_reserved_page_count) AS [internal object pages used],
  (SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in MB]
FROM tempdb.sys.dm_db_file_space_usage;

/*Query the amount of space used by user objects.*/
/*Microsoft provided query.*/
SELECT SUM(user_object_reserved_page_count) AS [user object pages used],
  (SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
FROM tempdb.sys.dm_db_file_space_usage;



/*Monster Query that shows session.*/
SELECT 
R1.session_id, 
R1.request_id, 
R1.Task_request_internal_objects_alloc_page_count, 
R1.Task_request_internal_objects_dealloc_page_count,
R1.Task_request_user_objects_alloc_page_count,
R1.Task_request_user_objects_dealloc_page_count,
R3.Session_request_internal_objects_alloc_page_count ,
R3.Session_request_internal_objects_dealloc_page_count,
R3.Session_request_user_objects_alloc_page_count,
R3.Session_request_user_objects_dealloc_page_count,
R2.sql_handle, 
RL2.text as SQLText, 
R2.statement_start_offset, 
R2.statement_end_offset, 
R2.plan_handle 
FROM 
(
SELECT session_id, request_id, 
SUM(internal_objects_alloc_page_count) AS Task_request_internal_objects_alloc_page_count, 
SUM(internal_objects_dealloc_page_count)AS Task_request_internal_objects_dealloc_page_count,
SUM(user_objects_alloc_page_count) AS Task_request_user_objects_alloc_page_count,
SUM(user_objects_dealloc_page_count) AS Task_request_user_objects_dealloc_page_count 
FROM sys.dm_db_task_space_usage 
GROUP BY session_id, request_id
) R1 
INNER JOIN 
(
SELECT session_id, SUM(internal_objects_alloc_page_count) AS Session_request_internal_objects_alloc_page_count,
SUM(internal_objects_dealloc_page_count) AS Session_request_internal_objects_dealloc_page_count,
SUM(user_objects_alloc_page_count) AS Session_request_user_objects_alloc_page_count,
SUM(user_objects_dealloc_page_count)AS Session_request_user_objects_dealloc_page_count 
FROM sys.dm_db_Session_space_usage 
GROUP BY session_id
) R3 
ON R1.session_id = R3.session_id 
left outer JOIN sys.dm_exec_requests R2 ON R1.session_id = R2.session_id and R1.request_id = R2.request_id
OUTER APPLY sys.dm_exec_sql_text(R2.sql_handle) AS RL2
Where
Task_request_internal_objects_alloc_page_count >0 or
Task_request_internal_objects_dealloc_page_count>0 or
Task_request_user_objects_alloc_page_count >0 or
Task_request_user_objects_dealloc_page_count >0 or
Session_request_internal_objects_alloc_page_count >0 or
Session_request_internal_objects_dealloc_page_count >0 or
Session_request_user_objects_alloc_page_count >0 or
Session_request_user_objects_dealloc_page_count >0
ORDER BY R1.session_id;
