---
title: Apache Livy - Apache Spark, HBase, and Kerberos
date: 2018-03-05 12:00:00 -06:00
tags:
- bigdata
- apache
- livy
- spark
- hbase
- kerberos
- security
layout: post
---

### Overview
[Apache Livy](https://livy.incubator.apache.org/) provides a [REST interface](https://livy.incubator.apache.org/docs/latest/rest-api.html) for interacting with [Apache Spark](https://spark.apache.org/). When using Apache Spark to interact with [Apache HBase](https://hbase.apache.org/) that is secured with [Kerberos](https://web.mit.edu/kerberos/), a Kerberos token needs to be obtained. This tends to pose some issues due to token delegation. `spark-submit` [provides a solution to this](https://issues.apache.org/jira/browse/SPARK-12279) by getting a delegation token on your behalf when the job is submitted. For this to work, HBase configurations and JAR files must be on the `spark-submit` classpath. Specifically which configurations an JAR files are explained in multiple references ([here](https://risdenk.gitbooks.io/hadoop_book/content/examples/spark_and_hbase.html), [here](http://www.opencore.com/blog/2016/3/spark-on-hbase-in-cluster-mode-with-secure-hbase/), and [here](https://community.hortonworks.com/content/supportkb/150066/how-to-run-a-spark-job-to-interact-with-a-secured.html)). Livy doesn't currently expose a way to dynamically add the required configuration and JARs to the `spark-submit` classpath. A long term solution could be explored with [LIVY-414](https://issues.apache.org/jira/browse/LIVY-414) which could allow the appropriate environment variables to be set when a Spark job is submitted.

### Assumptions
* [Apache Ambari](https://ambari.apache.org/) for managing [Apache Spark](https://spark.apache.org/) and [Apache Livy](https://livy.incubator.apache.org/)
* [Apache Knox](https://knox.apache.org/) in front of [Apache Livy](https://livy.incubator.apache.org/) secured with [Kerberos](https://web.mit.edu/kerberos/)
* [Apache HBase](https://hbase.apache.org/) secured with [Kerberos](https://web.mit.edu/kerberos/)

### Setup Spark Environment with Ambari
#### Add to bottom of `spark-env.sh`
```bash
export SPARK_CLASSPATH="/etc/hbase/conf:/usr/hdp/current/hadoop-client/hadoop-common.jar:/usr/hdp/current/hadoop-client/lib/guava-11.0.2.jar:/usr/hdp/current/hbase-client/lib/hbase-client.jar:/usr/hdp/current/hbase-client/lib/hbase-common.jar:/usr/hdp/current/hbase-client/lib/hbase-protocol.jar:/usr/hdp/current/hbase-client/lib/hbase-server.jar:/usr/hdp/current/hbase-client/lib/hbase-hadoop2-compat.jar:/usr/hdp/current/hbase-client/lib/htrace-core-3.1.0-incubating.jar"
```

#### Add to `spark-defaults.conf`
```
spark.driver.extraClassPath /etc/hbase/conf:/usr/hdp/current/hadoop-client/hadoop-common.jar:/usr/hdp/current/hadoop-client/lib/guava-11.0.2.jar:/usr/hdp/current/hbase-client/lib/hbase-client.jar:/usr/hdp/current/hbase-client/lib/hbase-common.jar:/usr/hdp/current/hbase-client/lib/hbase-protocol.jar:/usr/hdp/current/hbase-client/lib/hbase-server.jar:/usr/hdp/current/hbase-client/lib/hbase-hadoop2-compat.jar:/usr/hdp/current/hbase-client/lib/htrace-core-3.1.0-incubating.jar
spark.executor.extraClassPath /etc/hbase/conf:/usr/hdp/current/hadoop-client/hadoop-common.jar:/usr/hdp/current/hadoop-client/lib/guava-11.0.2.jar:/usr/hdp/current/hbase-client/lib/hbase-client.jar:/usr/hdp/current/hbase-client/lib/hbase-common.jar:/usr/hdp/current/hbase-client/lib/hbase-protocol.jar:/usr/hdp/current/hbase-client/lib/hbase-server.jar:/usr/hdp/current/hbase-client/lib/hbase-hadoop2-compat.jar:/usr/hdp/current/hbase-client/lib/htrace-core-3.1.0-incubating.jar
```

### Submitting an Example Spark HBase Job with Livy
#### Livy submission script
```bash
#!/usr/bin/env bash

curl \
  -u ${USER} \
  --location-trusted \
  -H 'X-Requested-by: livy' \
  -H 'Content-Type: application/json' \
  -X POST \
  https://localhost:8443/gateway/default/livy/v1/batches \
  --data "{
    \"proxyUser\": \"${USER}\",
    \"file\": \"hdfs:///user/${USER}/spark-hbase-kerberos-1.0-SNAPSHOT.jar\",
    \"className\": \"SparkHBaseKerberos\",
    \"args\": [
      \"tableName\"
    ]
  }"
```

#### Example `SparkHBaseKerberos` Class
```java
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.client.Connection;
import org.apache.hadoop.hbase.client.ConnectionFactory;
import org.apache.hadoop.hbase.client.Result;
import org.apache.hadoop.hbase.io.ImmutableBytesWritable;
import org.apache.hadoop.hbase.mapreduce.TableInputFormat;
import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaPairRDD;
import org.apache.spark.api.java.JavaSparkContext;

public class SparkHBaseKerberos {
  public static void main(String[] args) throws Exception {
    System.out.println("Starting");

    String tableName = args[0];
    System.out.println("tableName: " + tableName);

    SparkConf sparkConf = new SparkConf().setAppName(SparkHBaseKerberos.class.getCanonicalName());
    try (JavaSparkContext jsc = new JavaSparkContext(sparkConf)) {
      Configuration config = HBaseConfiguration.create();
      try (Connection connection = ConnectionFactory.createConnection(config)) {
        config.set(TableInputFormat.INPUT_TABLE, tableName);
        JavaPairRDD<ImmutableBytesWritable, Result> rdd = jsc.newAPIHadoopRDD(config, TableInputFormat.class, ImmutableBytesWritable.class, Result.class);
        System.out.println("Number of Records found: " + rdd.count());
      }

      System.out.println("Done");

      jsc.stop();
    }
  }
}
```

