---
title: Apache Ambari - Ranger HDFS Audit Logging Alert
date: 2018-03-03 12:00:00 -06:00
tags:
- bigdata
- apache
- ambari
- ranger
- hdfs
- audit
- logging
- alert
layout: post
---

### Overview
[Apache Ambari](https://ambari.apache.org/) makes managing distributed systems like [Apache Hadoop](https://hadoop.apache.org/) easier. One of the capabilities of Ambari is alerting. These alerts can alert administrators and trigger automatic recovery. We noticed that for [Apache Ranger](https://ranger.apache.org/) there were no alerts for HDFS audit logging. We rely on Ranger HDFS audit logging to ensure that accesses are tracked.

### Creating a Ranger HDFS Audit Logging Alert
We use Apache Ambari alerts for tracking system health across Apache Hadoop as well as other distributed systems like [Elasticsearch](https://www.elastic.co/products/elasticsearch). All of our Ambari alerts get sent to an email inbox and for production systems page our on call staff. @quirogadf came up with the idea of creating an Ambari alert to ensure that Ranger HDFS audits were being stored.

Since we had experience reviewing and modifying existing Ambari alerts to adjust them for our needs, it was possible for us to build our own alerts. @quirogadf worked on creating a simple Ambari alert to check that a Ranger HDFS audit folders were created for each day.

David created a single Python script which is parameterized to create alerts for individual services (ie: HDFS, Hive, HBase, etc). This script was modeled after existing Ambari alerts and is cluster agnostic using Ambari configuration properties. The script is located [here](https://issues.apache.org/jira/secure/attachment/12903985/alert_ranger_logging.py).

Each service can have an alert created with a JSON file with a few parameters. An example for HDFS is below.
```json
{
      "AlertDefinition":{
      "service_name":"CUSTOM_ALERTS",
      "component_name":"CUSTOM_ALERTS_SERVER",
      "name": "ranger_hdfs_hdfs_logging_health",
      "label": "Ranger HDFS logging to HDFS Health",
      "description": "Confirm that daily Ranger-HDFS audit files are being created in HDFS.",
      "interval": 480,
      "scope": "ANY",
      "enabled": true,
      "ignore_host": false,
      "source": {
        "type": "SCRIPT",
        "path": "alert_ranger_logging.py",
        "parameters": [
            {
              "name": "service.type.name",
              "display_name": "Service Type",
              "value": "hdfs",
              "type": "STRING",
              "description": "Service Type audit logs to be checked by this alert. i.e. knox, hbase, storm, hdfs",
              "visibility": "HIDDEN"
            },
            {
              "name": "service.hdfs.dir.name",
              "display_name": "Service HDFS directory name",
              "value": "hdfs",
              "type": "STRING",
              "description": "The Service's HDFS directory name under the audit destination directory (/ranger/audit)",
              "visibility": "HIDDEN"
            },
            {
              "name": "default.smoke.user",
              "display_name": "Default Smoke User",
              "value": "ambari-qa",
              "type": "STRING",
              "description": "The user that will run the Hive commands if not specified in cluster-env/smokeuser",
              "visibility": "HIDDEN"
            },
            {
              "name": "default.smoke.principal",
              "display_name": "Default Smoke Principal",
              "value": "ambari-qa@EXAMPLE.COM",
              "type": "STRING",
              "description": "The principal to use when retrieving the kerberos ticket if not specified in cluster-env/smokeuser_principal_name",
              "visibility": "HIDDEN"
            },
            {
              "name": "default.smoke.keytab",
              "display_name": "Default Smoke Keytab",
              "value": "/etc/security/keytabs/smokeuser.headless.keytab",
              "type": "STRING",
              "description": "The keytab to use when retrieving the kerberos ticket if not specified in cluster-env/smokeuser_keytab",
              "visibility": "HIDDEN"
            }
          ]
        }
      }
}
```

### What is next?
@quirogadf created [AMBARI-22708](https://issues.apache.org/jira/browse/AMBARI-22708) and uploaded the Python script along with examples of JSON alert definitions. We are waiting on the Apache Ambari community to review the JIRA and decide if this is useful for the community. In the meantime, we have successfully used this new alert to ensure that our Apache Ranger HDFS audits continue to work.

