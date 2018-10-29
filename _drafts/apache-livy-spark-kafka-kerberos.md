---
title: TODO - Apache Livy - Apache Spark, Kafka, and Kerberos
date: 2018-10-29 17:47:13.266000000 -05:00
tags:
- bigdata
- apache
- livy
- spark
- kafka
- kerberos
- security
layout: post
---

* https://risdenk.gitbooks.io/hadoop_book/content/examples/spark_and_kafka.html
* https://cwiki.apache.org/confluence/display/KAFKA/KIP-85%3A+Dynamic+JAAS+configuration+for+Kafka+clients
* Use new consumer api for Spark instead of Zookeeper

### Overview
[Apache Livy](https://livy.apache.org/) provides a [REST interface](https://livy.incubator.apache.org/docs/latest/rest-api.html) for interacting with [Apache Spark](https://spark.apache.org/). 

### TODO
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
    \"conf\": {
      \"spark.yarn.appMasterEnv.PYSPARK_PYTHON\": \"$PYSPARK_PYTHON\"
    },
    \"file\": \"hdfs:///user/${USER}/TensorFlowOnSpark/examples/mnist/mnist_data_setup.py\"
  }" | python -m json.tool
```

