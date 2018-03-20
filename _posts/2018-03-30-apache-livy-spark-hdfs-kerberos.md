---
title: Apache Livy - Apache Spark, HDFS, and Kerberos
date: 2018-03-30 09:00:00 -05:00
tags:
- bigdata
- apache
- livy
- spark
- hdfs
- kerberos
- security
layout: post
---

### Overview
[Apache Livy](https://livy.incubator.apache.org/) provides a [REST interface](https://livy.incubator.apache.org/docs/latest/rest-api.html) for interacting with [Apache Spark](https://spark.apache.org/). When using Apache Spark to interact with [Apache Hadoop HDFS](https://hadoop.apache.org/) that is secured with [Kerberos](https://web.mit.edu/kerberos/), a Kerberos token needs to be obtained. This tends to pose some issues due to token delegation. 

`spark-submit` [provides a solution to this](https://issues.apache.org/jira/browse/SPARK-12279) by getting a delegation token on your behalf when the job is submitted. For this to work, Hadoop configurations and JAR files must be on the `spark-submit` classpath. Specifically which configurations an JAR files are explained in a references [here](https://risdenk.gitbooks.io/hadoop_book/content/examples/spark_and_hdfs.html).

When using Livy with HDP, the Hadoop JAR files and configurations are already on the classpath for `spark-submit`. This means there is nothing special required to read/write to HDFS with a Spark job submitted through Livy.

If you are looking to do something similar with [Apache HBase](https://hbase.apache.org/) see this [post](/2018/03/05/apache-livy-spark-hbase-kerberos.html).

### Assumptions
* [Apache Ambari](https://ambari.apache.org/) for managing [Apache Spark](https://spark.apache.org/) and [Apache Livy](https://livy.incubator.apache.org/)
* [Apache Knox](https://knox.apache.org/) in front of [Apache Livy](https://livy.incubator.apache.org/) secured with [Kerberos](https://web.mit.edu/kerberos/)
* [Apache Hadoop HDFS](https://hadoop.apache.org/) secured with [Kerberos](https://web.mit.edu/kerberos/)

### `run.sh`
```bash
curl \
  -u ${USER} \
  --location-trusted \
  -H 'X-Requested-by: livy' \
  -H 'Content-Type: application/json' \
  -X POST \
  https://localhost:8443/gateway/default/livy/v1/batches \
  --data "{
    \"proxyUser\": \"${USER}\",
    \"file\": \"hdfs:///user/${USER}/SparkHDFSKerberos.jar\",
    \"className\": \"SparkHDFSKerberos\",
    \"args\": [
      \"hdfs://PATH_TO_FILE\"
    ]
  }"
```

### `SparkHDFSKerberos`
```java
import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;

public class SparkHDFSKerberos {
  public static void main(String[] args) {
    SparkConf sparkConf = new SparkConf().setAppName(SparkHDFSKerberos.class.getCanonicalName());
    JavaSparkContext jsc = new JavaSparkContext(sparkConf);

    JavaRDD<String> textFile = jsc.textFile(args[0]);
    System.out.println(textFile.count());

    jsc.stop();
    jsc.close();
  }
}
```

