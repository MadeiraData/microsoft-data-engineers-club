
/*********************************************************************************************************
Author:			Eitan Blumin @Madeira
Created Date:	2025-02-04
Description:	This script retrieve index usage stats for each table in Azure Synapse Analytics
**********************************************************************************************************/

SELECT
    SchemaName  = sch.[name] ,
    TableName   = t.[name] ,
    ius.*
FROM
    sys.schemas AS sch
INNER JOIN
    sys.tables AS t
ON
    sch.[schema_id] = t.[schema_id]
INNER JOIN
    sys.indexes AS ix
ON
    t.[object_id] = ix.[object_id]
AND
    ix.[index_id] <= 1
INNER JOIN
    sys.pdw_permanent_table_mappings AS tmap
ON
    t.[object_id] = tmap.[object_id]
INNER JOIN
    sys.pdw_nodes_tables AS ntab
ON
    tmap.[physical_name] = ntab.[name]
LEFT JOIN
    sys.dm_pdw_nodes_db_index_usage_stats AS ius
ON
    ntab.[object_id] = ius.[object_id]
AND ntab.[pdw_node_id] = ius.[pdw_node_id]
--AND ntab.[distribution_id] = ius.[distribution_id]
--GROUP BY
--    sch.[name] ,
--    t.[name];
GO