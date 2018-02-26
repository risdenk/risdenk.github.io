---
title: Apache Knox - Apache Livy Service
date: 2018-03-02 12:00:00 -06:00
tags:
- bigdata
- apache
- knox
- livy
- spark
layout: post
---

### Overview
[Apache Knox](https://knox.apache.org/) is a reverse proxy that simplifies security in front of a Kerberos secured [Apache Hadoop](https://hadoop.apache.org/) cluster and other related components. Knox can be extended with [custom services](https://cwiki.apache.org/confluence/display/KNOX/2015/12/17/Adding+a+service+to+Apache+Knox) to support authenticating compoents that aren't originally shipped with a release. One of the services we wanted Apache Knox support for was [Apache Livy](https://livy.incubator.apache.org/), a REST API for interacting with [Apache Spark](https://spark.apache.org/).

### Why use an Apache Knox service for Apache Livy?
Apache Knox simplifies deployments with multiple REST services since the authentication can be handled in a single location. Knox also significantly simplifies end user interactions since they don't need to deal with Kerberos authentication. Apache Livy, when configured with Kerberos, is hard to use and interact with. Apache Knox makes this simple but supporting basic authentication via LDAP as well as other authentication mechanisms. 

### Adding and using the Apache Knox service for Apache Livy
@bernhard-42 created a Hortonworks Community Connection [post](https://community.hortonworks.com/articles/70499/adding-livy-server-as-service-to-apache-knox.html) showing that it was possible to add Apache Livy to Knox. [KNOX-842](https://issues.apache.org/jira/browse/KNOX-842) was created in January 2017 to get Apache Knox to support Apache Livy as part of a release. In September 2017, I worked with @westeras to incorporate Livy into our Knox server. We were able to test the patch uploaded by @JeffRodriguez successfully ensuring that Kerberos authentication worked correctly. In December 2017, [Apache Knox 0.14.0](https://cwiki.apache.org/confluence/display/KNOX/Release+0.14.0) was released supporting the initial version of Apache Livy support.

### What is next?
There are a few minor issues with the initial version of Apache Livy support. Most of these are easily worked around and are for future improvement.
* [KNOX-1098](https://issues.apache.org/jira/browse/KNOX-1098) - Improve `proxyUser` handling
* [KNOX-1056](https://issues.apache.org/jira/browse/KNOX-1056) - Documentation for Spark/Livy support
* [KNOX-1148](https://issues.apache.org/jira/browse/KNOX-1148) - Remove v1 from Livy service url

You can help out by attaching a patch or providing feedback to the [Apache Knox community](https://knox.apache.org/).

