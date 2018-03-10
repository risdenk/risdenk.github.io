---
title: Apache Ranger - Hive over HDFS Audit Logs
date: 2018-03-23 12:00:00 -06:00
tags:
- bigdata
- apache
- ranger
- hive
- hdfs
- audit
- logs
- security
layout: post
---

### Overview
[Apache Ranger](https://ranger.apache.org/) allows for centralized authorization and auditing for [Apache Hadoop](https://hadoop.apache.org/) and related technologies. Ranger auditing can be stored in multiple locations including [Apache Solr](https://lucene.apache.org/solr/) and [HDFS](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html). With HDFS storing audit logs for compliance purposes, we needed a way to query these logs. [Apache Hive](https://hive.apache.org/) provides the ability to query HDFS data without a lot of effort. This has been written about before [here](* https://community.hortonworks.com/articles/60802/ranger-audit-in-hive-table-a-sample-approach-1.html) as well. The post below outlines a similar approach with slightly different details.

### Ranger Audit Log Format on HDFS
Currently, Apache Ranger stores audit logs in HDFS in a standard JSON format. The audit schema is detailed [here](https://cwiki.apache.org/confluence/display/RANGER/Ranger+Audit+Schema). Previously I wrote about how these logs could be compressed [here](/2018/02/26/apache-ranger-hdfs-audit-logging-compression.html). The format could change to make the process below easier with [RANGER-1837](https://issues.apache.org/jira/browse/RANGER-1837).

### Creating the Hive table over Ranger Audit Logs on HDFS
Since the data is in JSON format on HDFS, there are a few options for what [Hive SerDe](https://cwiki.apache.org/confluence/display/Hive/SerDe) to use. The built in [Hive JSON SerDe](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DDL#LanguageManualDDL-RowFormats&SerDe) has issues when the data is malformed, which from experience can happen with the Ranger audit data. @rcongiu has a Hive JSON SerDe - [https://github.com/rcongiu/Hive-JSON-Serde](https://github.com/rcongiu/Hive-JSON-Serde) that can handle the malformed JSON data easily.

The Ranger audit log format on HDFS dictates that the folder structure include `component` and `evtDate`. This folder structure makes it possible to define a [partitioned Hive table](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DDL#LanguageManualDDL-AlterPartition) which [improves query performance](https://blog.cloudera.com/blog/2014/08/improving-query-performance-using-partitioning-in-apache-hive/) when looking at a specific date range or component. 

```sql
ADD JAR hdfs:///INSERT_PATH_TO/json-serde-VERSION-jar-with-dependencies.jar;

DROP TABLE IF EXISTS ranger_audit;
CREATE EXTERNAL TABLE ranger_audit (
  resource string,
  resType string,
  reqUser string,
  evtTime TIMESTAMP,
  policy int,
  access string,
  result int,
  reason string,
  enforcer string,
  repoType int,
  repo string,
  cliIP string,
  action string,
  agentHost string,
  logType string,
  id string
)
PARTITIONED BY (component String, evtDate String)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe' WITH SERDEPROPERTIES ( "ignore.malformed.json" = "true");
```

For each partition (`component` and `evtDate`), you will need to alter the table to add the partition. I scripted this out to automatically add new partitions as necessary. Example of doing this for one partition:

```sql
ALTER TABLE ranger_audit ADD IF NOT EXISTS PARTITION (component='COMPONENT_NAME', evtDate='DATE') LOCATION 'DATE_FOLDER';
```

### Using Hive to Query Ranger Audit Logs on HDFS
After the Hive table has been created, it is possible to issue [Hive SQL queries](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Select) across the Ranger audit logs. Some query examples are below:

```sql
-- Get total number of events
SELECT count(1) FROM ranger_audit;

-- Get total number of events for HDFS
SELECT count(1) FROM ranger_audit WHERE component='HDFS';

-- Get total number of events on 2018-03-23
SELECT count(1) FROM ranger_audit WHERE evtDate='2018-03-23';

-- Get total number of events for HDFS on 2018-03-23
SELECT count(1) FROM ranger_audit WHERE component='HDFS' and evtDate='2018-03-23';
```

These queries can be run in multiple different tools including [Apache Zeppelin](https://zeppelin.apache.org/) which can generate charts and graphs. Additionally, after the Hive table has been created it can be easily exposed over JDBC/ODBC.

