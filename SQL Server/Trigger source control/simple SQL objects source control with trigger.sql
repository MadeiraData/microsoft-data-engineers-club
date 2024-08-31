/*******************************
Created By - Chen Hirsh
Created On - 2024-08-24
Script to save changed in SQL objects (Stored Procedures, Views) in an audit table by using a DDL trigger.
Based on the blog By Aaron Bertrand - https://www.mssqltips.com/sqlservertip/2085/sql-server-ddl-triggers-to-track-all-database-changes/

I changed the code a bit for Azure SQL Database, and to include views.
All objects will be saved to the current database. If you need, change the trigger and location of the audit table to another database
*******************************/

--create the audit table
CREATE TABLE dbo.DDLEvents
(
    EventDate    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    EventType    NVARCHAR(64),
    EventDDL     NVARCHAR(MAX),
    EventXML     XML,
    DatabaseName NVARCHAR(255),
    SchemaName   NVARCHAR(255),
    ObjectName   NVARCHAR(255),
    HostName     VARCHAR(64),
    IPAddress    VARCHAR(48),
    ProgramName  NVARCHAR(255),
    LoginName    NVARCHAR(255)
);
Go

--save current code to the table

--Stored Procedures
INSERT dbo.DDLEvents
(
    EventType,
    EventDDL,
    DatabaseName,
    SchemaName,
    ObjectName,
    LoginName
)
SELECT
    'CREATE_PROCEDURE',
    OBJECT_DEFINITION([object_id]),
    DB_NAME(),
    OBJECT_SCHEMA_NAME([object_id]),
    OBJECT_NAME([object_id]),
    SUSER_NAME()
FROM
    sys.procedures;
Go

--Views
INSERT dbo.DDLEvents
(
    EventType,
    EventDDL,
    DatabaseName,
    SchemaName,
    ObjectName,
    LoginName
)
SELECT
    'CREATE_VIEW',
    OBJECT_DEFINITION([object_id]),
    DB_NAME(),
    OBJECT_SCHEMA_NAME([object_id]),
    OBJECT_NAME([object_id]),
    SUSER_NAME()
FROM
    sys.views;
Go


-- Create the trigger
CREATE TRIGGER DDLTrigger_code_save
    ON DATABASE
    FOR CREATE_PROCEDURE, ALTER_PROCEDURE, DROP_PROCEDURE,
		CREATE_VIEW, ALTER_VIEW, DROP_VIEW
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE
        @EventData XML = EVENTDATA();
 
    DECLARE @ip varchar(48) = CONVERT(varchar(48), 
        CONNECTIONPROPERTY('client_net_address'));
 
    INSERT dbo.DDLEvents
    (
        EventType,
        EventDDL,
        EventXML,
        DatabaseName,
        SchemaName,
        ObjectName,
        HostName,
        IPAddress,
        ProgramName,
        LoginName
    )
    SELECT
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]',   'NVARCHAR(100)'), 
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)'),
        @EventData,
        DB_NAME(),
        @EventData.value('(/EVENT_INSTANCE/SchemaName)[1]',  'NVARCHAR(255)'), 
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]',  'NVARCHAR(255)'),
        HOST_NAME(),
        @ip,
        PROGRAM_NAME(),
        SUSER_SNAME();
END
GO


--if you need to disable the trigger (uncomment the row below)
--DISABLE TRIGGER DDLTrigger_code_save ON DATABASE;


--views the code in the table
select 
	ObjectName,
	EventDate,
	EventType,
	EventDDL
from dbo.DDLEvents
where ObjectName='test_v'
order by EventDate desc