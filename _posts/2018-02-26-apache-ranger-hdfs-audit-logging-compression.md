---
title: Apache Ranger - HDFS Audit Logging Compression
date: 2018-02-26 12:00:00 -06:00
tags:
- bigdata
- apache
- ranger
- hdfs
- audit
- logging
- compression
layout: post
---

### Overview
[Apache Ranger](https://ranger.apache.org/) allows for centralized authorization and auditing for [Apache Hadoop](https://hadoop.apache.org/) and related technologies. Ranger auditing can be stored in multiple locations including [Apache Solr](https://lucene.apache.org/solr/) and [HDFS](http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html). Apache Solr provides short term storage for administrators to review audit logs. HDFS provides long term storage of audit logs for compliance purposes.

### Apache Ranger HDFS Audit Log Format
Apache Ranger [stores audit logs on HDFS](https://cwiki.apache.org/confluence/display/RANGER/Ranger+0.5+Audit+Configuration#Ranger0.5AuditConfiguration-AudittoHDFS) in [JSON format uncompressed](https://cwiki.apache.org/confluence/display/RANGER/Ranger+Audit+Schema#RangerAuditSchema-AudittoHDFS). Each line of the audit log contains a full JSON object. The audit logs are separated into a folder per day as well. The HDFS Audit logs are not accessed frequently since most queries go against the Apache Solr short term storage.

**Apache Ranger HDFS Audit Log Example**
```json
{"repoType":1,"repo":"MYCLUSTER_hadoop","reqUser":"hbase","evtTime":"2018-02-26 14:07:35.335","access":"READ_EXECUTE","resource":"/apps/hbase/data/archive/data/namespace/table/rowkey/cf","resType":"path","action":"read","result":1,"policy":-1,"reason":"/apps/hbase/data/archive/data/namespace/table/rowkey/cf","enforcer":"hadoop-acl","cliIP":"192.168.1.100","agentHost":"myhost.fqdn","logType":"RangerAudit","id":"UUID","seq_num":36054670,"event_count":1,"event_dur_ms":0,"tags":[]}
```

### HDFS Audit Storage Requirements
The HDFS Audit Log Format is verbose for long term storage. The JSON format is human readable, but for auditing takes up too much space. On one cluster we are on track to generate ~10TB of data for one year. This is a significant amount of storage which could be easily be reduced with compression or a different storage format. Furthermore, since the audit logs are not accessed frequently the trade off of space vs time could be made.

### Reducing HDFS Audit Storage Requirements
In October 2017, I emailed the [Apache Ranger mailing list](http://mail-archives.apache.org/mod_mbox/ranger-user/201710.mbox/%3CCAJU9nmiYzzUUX1uDEysLAcMti4iLmX7RE%3DmN2%3DdoLaaQf87njQ%40mail.gmail.com%3E) to ask if compression for HDFS audit was on the radar. Since JSON is basically text, GZIP compression could result in up to 90% compression. We had done some quick testing and found that the Apache Ranger HDFS audit logs could be compressed to reduce space required. Our ~10TB HDFS audit logs could be reduced to ~1TB resulting in ~90% less storage needed to meet compliance storage. The Apache Ranger community suggested that ORC format would provide reduced storage requirements. This would also allow for easily querying with [Apache Hive](https://hive.apache.org/).

### What is next?
I created [RANGER-1837](https://issues.apache.org/jira/browse/RANGER-1837) to track further developments. Ramesh Mani has been working on implementing an ORC HDFS audit format. Currently there is a patch that requires reviewing and testing. Once the patch is reviewed and tested, it can become part of Apache Ranger.

