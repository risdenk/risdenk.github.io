---
title: Apache Ambari - WEB Alerts - Don't Use HTTP Principal
date: 2018-02-25 12:00:00 -06:00
tags:
- bigdata
- apache
- ambari
- alert
- SPNEGO
- kerberos
- HTTP
layout: post
---

### Overview
[Apache Ambari](https://ambari.apache.org/) makes managing distributed systems like [Apache Hadoop](https://hadoop.apache.org/) easier. One of the capabilities of Ambari is alerting. These alerts can alert administrators and trigger automatic recovery. While reviewing [Apache Ranger](https://ranger.apache.org/) audit logs, @quirogadf noticed that we had a lot of `HTTP` users being denied for the [YARN](https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/YARN.html) service. @quirogadf looked into this closer and realized that the alert was using `HTTP/_HOST@REALM` instead of the `ambari-qa` user or another test user. @quirogadf opened [AMBARI-23026](https://issues.apache.org/jira/browse/AMBARI-23026) to inform the Apache Ambari community of this error.

### Proper Ambari alerts user = `ambari-qa`
The proper Ambari alerts user is the `ambari-qa` user instead of `HTTP/_HOST@REALM`. The `HTTP/_HOST@REALM` principal is meant for authenticating web endpoints only. It is not meant to be used for authentication to other services. The `Service Principal Name` (`SPN`) of `HTTP/_HOST` is special and used for SPNEGO authentication with Kerberos. The `ambari-qa` user is a special user created by Ambari specifically for service checks and alerts.

### What service alerts are using the `HTTP/_HOST` principal?
The below command finds all `alerts.json` files that use a `kerberos_principal` that isn't `ambari-qa` (specified with `smokeuser_principal_name`).

```
ambari git:(trunk) for x in $(find . -name alerts.json); do grep kerberos_principal $x /dev/null; done | grep -v smokeuser_principal_name | cut -d':' -f1 | sort -u
./ambari-server/src/main/resources/common-services/AMBARI_INFRA_SOLR/0.1.0/alerts.json
./ambari-server/src/main/resources/common-services/FALCON/0.5.0.2.1/alerts.json
./ambari-server/src/main/resources/common-services/HBASE/0.96.0.2.0/alerts.json
./ambari-server/src/main/resources/common-services/HDFS/2.1.0.2.0/alerts.json
./ambari-server/src/main/resources/common-services/STORM/0.9.1/alerts.json
./ambari-server/src/main/resources/common-services/YARN/2.1.0.2.0/alerts.json
./ambari-server/src/main/resources/stacks/BIGTOP/0.8/services/HDFS/alerts.json
./ambari-server/src/main/resources/stacks/BIGTOP/0.8/services/YARN/alerts.json
./contrib/management-packs/odpi-ambari-mpack/src/main/resources/stacks/ODPi/2.0/services/YARN/alerts.json
```

Based on the above list, the follow Ambari services need to be fixed:
* [`AMBARI_INFRA_SOLR`](https://github.com/apache/ambari/blob/trunk/ambari-server/src/main/resources/common-services/AMBARI_INFRA_SOLR/0.1.0/alerts.json)
* [`FALCON`](https://github.com/apache/ambari/blob/trunk/ambari-server/src/main/resources/common-services/FALCON/0.5.0.2.1/alerts.json)
* [`HBASE`](https://github.com/apache/ambari/blob/trunk/ambari-server/src/main/resources/common-services/HBASE/0.96.0.2.0/alerts.json)
* [`HDFS`](https://github.com/apache/ambari/blob/trunk/ambari-server/src/main/resources/common-services/HDFS/2.1.0.2.0/alerts.json)
* [`STORM`](https://github.com/apache/ambari/blob/trunk/ambari-server/src/main/resources/common-services/STORM/0.9.1/alerts.json)
* [`YARN`](https://github.com/apache/ambari/blob/trunk/ambari-server/src/main/resources/common-services/YARN/2.1.0.2.0/alerts.json)

### Fixing Ambari Alerts to use the `ambari-qa` user
The alerts can be modified by updating the [Ambari alert definition](https://github.com/apache/ambari/blob/trunk/ambari-server/docs/api/v1/alert-definitions.md). 

Steps to update the Ambari Alerts
* Find the alert id (`http://<AMBARI_HOST>/api/v1/clusters/<CLUSTER>/alert_definitions`)
* Download the alert json (`http://<AMBARI_HOST>/api/v1/clusters/<CLUSTER>/alert_definitions/<ID>`)
* Edit the alert json locally with `cluster-env/smokeuser_keytab` and `cluster-env/smokeuser_principal_name` for keytab and principal name respectively
* [Update the alert definition](https://github.com/apache/ambari/blob/trunk/ambari-server/docs/api/v1/alert-definitions.md#update) by pushing the alert json
    * `curl -U username -i -XPUT 'http://<AMBARI_HOST>/api/v1/clusters/<CLUSTER>/alert_definitions/<ID> -d@alert_json.json`

### What is next?
Big shout out to @quirogadf for tracking this down and creating [AMBARI-23026](https://issues.apache.org/jira/browse/AMBARI-23026). Follow [AMBARI-23026](https://issues.apache.org/jira/browse/AMBARI-23026) to see when this will be fixed upstream in Ambari. Currently it is tagged for Ambari 2.7.0 but has not been committed yet.

