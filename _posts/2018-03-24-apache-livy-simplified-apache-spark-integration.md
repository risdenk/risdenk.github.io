---
title: Apache Livy - Simplified Apache Spark Integration
date: 2018-03-24 13:00:00 -05:00
tags:
- bigdata
- apache
- livy
- spark
- simplify
- integration
- zeppelin
- anaconda
- jupyter
- nifi
layout: post
---

### Overview
[Apache Livy](https://livy.apache.org/) provides a [REST interface](https://livy.incubator.apache.org/docs/latest/rest-api.html) for interacting with [Apache Spark](https://spark.apache.org/). Prior to Livy, Apache Spark typically required running [`spark-submit`](https://spark.apache.org/docs/latest/submitting-applications.html) from the command line or required tools to run `spark-submit`. This was not feasible in many situations and made security around Spark hard. 

### Apache Livy History
[Cloudera originally built Livy](https://blog.cloudera.com/blog/2016/07/livy-the-open-source-rest-service-for-apache-spark-joins-cloudera-labs/) to solve these problems by providing an interface by which Spark jobs can be submitted and monitored easily. Hortonworks decided to support and improve Livy as indicated [here](https://hortonworks.com/blog/livy-a-rest-interface-for-apache-spark/) and [here](https://hortonworks.com/blog/recent-improvements-apache-zeppelin-livy-integration/). Livy to the [Apache Software Foundation](https://www.apache.org/) and is in the [incubator process currently](https://livy.apache.org). Many other companies and tools have started using Apache Livy as an integration point for interacting with Apache Spark. Outlined below is an example of what Apache Livy enables.

### Apache Livy Architecture
<p style="text-align:center"><img width="700" src="/images/posts/2018-03-24/apache_livy_architecture.svg" /></p>

### Integration with Apache Livy
As diagramed above, Apache Livy integrates with many different tools to enable users to quickly and securely use Apache Spark. Microsoft with [Azure HDInsight supports Apache Livy](https://docs.microsoft.com/en-us/azure/hdinsight/spark/apache-spark-livy-rest-interface) for connecting to Spark clusters. [Jupyter Notebook](https://jupyter.org/), an open source web based notebook, can [use Livy with `sparkmagic`](https://github.com/jupyter-incubator/sparkmagic) to interact with Spark. Another web based notebook solution, [Apache Zeppelin](https://zeppelin.apache.org) integrates [natively with Livy](https://zeppelin.apache.org/docs/latest/interpreter/livy.html). [Anaconda](https://www.anaconda.com/), which supports both Jupyter and Apache Zeppelin, [works with Livy (video)](https://www.youtube.com/watch?v=wa514mI7Aw4) as well. Recently [Apache NiFi](https://nifi.apache.org/) added support for [submitting Spark jobs via Livy](https://community.hortonworks.com/articles/73828/submitting-spark-jobs-from-apache-nifi-using-livy.html). Finally, [Apache Knox](https://knox.apache.org/) can provide LDAP authentication [in front of Apache Livy](/2018/03/02/apache-knox-apache-livy-service.html).

All of the integrations above make it easier to use Apache Spark without requiring `spark-submit` due to Apache Livy. Building on top of Apache Livy provides a great abstraction to not worry about where the Spark job will be run.

### What is next?
Over the past year, I have been working with my team and multiple analytics teams to simplify the experience of getting started and using [Apache Spark](https://spark.apache.org/). [Apache Livy](https://livy.apache.org/) provides the capabitilies necessary to do this without compromising on ease of use or security. Since much of the documentation for Apache Spark revolves around [`spark-submit`](https://spark.apache.org/docs/latest/submitting-applications.html), I have been looking into converting those examples to work with Apache Livy.

