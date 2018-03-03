---
title: Apache Zookeeper - Changing Kerberos Principal - AuthFailedException
date: 2018-03-13 13:00:00 -05:00
tags:
- bigdata
- apache
- zookeeper
- kerberos
- principal
- AuthFailedException
- security
layout: post
---

### TL;DR
Changing the Kerberos principal for [Apache Zookeeper](https://zookeeper.apache.org/) causes an `AuthFailedException` that must be fixed on the client side with `-Dzookeeper.sasl.client.username=CUSTOM_ZK_PRINCIPAL`.

### Overview
In July of 2015, while at [Avalon Consulting, LLC](https://www.avalonconsult.com), I spent two weeks working with a company to secure their [Hortonworks Data Platform (HDP)](https://hortonworks.com/products/data-platforms/hdp/) cluster. This included SSL, LDAP, and Kerberos. One of the factors that required some additional effort was the requirement that Linux usernames must be 8 characters, which affected Kerberos principal length as well. This requirement was enforced by [Centrify](https://www.centrify.com/) but this could have been enforced through other means. The other day I found that the same problem exists today ~3+ years after I had successfully completed the security implementation. Hopefully this blog helps avoid future headaches when dealing with changing principals, especially [Apache Zookeeper](https://zookeeper.apache.org/).

### Effects of Changing the Apache Zookeeper Principal
[Apache Ambari](https://ambari.apache.org/) during the ["Enable Kerberos" wizard](https://cwiki.apache.org/confluence/display/AMBARI/Automated+Kerberizaton) does permit changing the principals that get generated. This customer wanted 8 character user names so we changed the corresponding principals to follow that requirement. The [Kerberos](https://web.mit.edu/kerberos/) wizard completed succcessully up until the service start portion. Many of the services started correctly but there were a few that wouldn't come up.

The few I remember that failed were [HDFS ZKFC](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithNFS.html), [Apache HBase](https://hbase.apache.org/), and [Apache Storm](https://storm.apache.org/). The common trend was that it was any service that had to connect to [Apache Zookeeper](https://zookeeper.apache.org). There were errors in the logs about not being able to authenticate to Zookeeper due to [`SASL` authentication](https://en.wikipedia.org/wiki/Simple_Authentication_and_Security_Layer).

Example Zookeeper client error message:
```
org.apache.zookeeper.KeeperException$AuthFailedException: KeeperErrorCode = AuthFailed for ...
```

### Fixing Zookeeper Clients for a Custom Zookeeper Principal
The root cause of the problem after some digging was that Zookeeper assumed that the service principal was `zookeeper`. [ZOOKEEPER-1811](https://issues.apache.org/jira/browse/ZOOKEEPER-1811) changed the hardcoded `zookeeper` string to a property that could be configured. The new property [`zookeeper.sasl.client.username`](http://zookeeper.apache.org/doc/r3.5.3-beta/zookeeperProgrammers.html#sc_java_client_configuration) allowed a user to adjust on the client side the principal. Since this a client side setting, all clients of Zookeeper needed to have this property configured. The system property that needed to be set is shown below.

```
-Dzookeeper.sasl.client.username=CUSTOM_ZK_PRINCIPAL_NAME
```

For [Apache Zookeeper](https://zookeeper.apache.org/) since it is a client of itself, the `JVMFLAGS` property must be set in `Zookeeper Env -> client_opts` or on the command line `JVMFLAGS="-Dsun.security.krb5.debug=true -Dzookeeper.sasl.client.username=zk" /usr/hdp/current/zookeeper-client/bin/zkCli.sh -server SERVERNAME`

For [Apache Hadoop HDFS](https://hadoop.apache.org/), the system property must be added to `Hadoop Env -> HADOOP_OPTS`. For [Apache HBase](https://hbase.apache.org/), the system property must be added to `HBase Env -> HBASE_OPTS`. For [Apache Storm](https://storm.apache.org/), the system property must be added to `nimbus.childopts`, `supervisor.childopts`, and `worker.childopts`. At the time, [Ambari Infra Solr](https://ambari.apache.org/), [Ambari Metrics](https://cwiki.apache.org/confluence/display/AMBARI/Metrics), and [Kafka](https://kafka.apache.org/) didn't exist but the same system property would be needed as described [here](https://community.hortonworks.com/questions/21118/hive-storm-kafka-hbase-cannot-connect-to-zookeeper.html) and [here](https://community.hortonworks.com/articles/108144/hdfs-yarn-infrasolr-zk-client-when-using-custom-zo.html).

### Current Status of Apache Ambari and Custom Principals
I haven't checked how Apache Ambari handles custom principals in the last year or so. I know there have been significant improvements to how Ambari secures Apache Hadoop clusters. Apache Ambari 2.5.0 added Zookeeper ACLs and authentication for a bunch of services. According to [this post](https://community.hortonworks.com/articles/108144/hdfs-yarn-infrasolr-zk-client-when-using-custom-zo.html) the problem described is still a problem with HDP 2.6.x and Ambari 2.5.x. Ambari 2.6.x is out but could have the same issues.

Regardless of how improved Apache Ambari becomes, I would suggest not to change the principals for Zookeeper or other services since it could cause a lot of problems.

