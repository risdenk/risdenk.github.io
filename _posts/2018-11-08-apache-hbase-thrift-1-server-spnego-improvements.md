---
title: Apache HBase - Thrift 1 Server SPNEGO Improvements
date: 2018-11-08 08:00:00 -06:00
tags:
- bigdata
- apache
- hbase
- thrift
- spnego
- kerberos
- security
- hue
layout: post
---

### Overview
[Apache HBase](https://hbase.apache.org/) provides the ability to perform realtime random read/write access to large datasets. HBase is built on top of [Apache Hadoop](https://hadoop.apache.org/) and can scale to billions of rows and millions of columns. One of the capabilities of Apache HBase is a [thrift server](https://hbase.apache.org/book.html#thrift) that provides the ability to interact with HBase from any language that supports [Thrift](https://thrift.apache.org/). There are two different versions of the HBase Thrift server v1 and v2. This blog post focuses on v1 since that is the version that integrates with [Hue](https://gethue.com/).

### Apache HBase and Hue
[Hue has support for Apache HBase](https://gethue.com/the-web-ui-for-hbase-hbase-browser/) through the v1 thrift server. The Hue UI allows for easily interacting with HBase for both querying and inserting. It is a quick and easy way to get started with HBase. The downside is that when using the HBase thrift v1 server, there was limited support for Kerberos.

### HBase Thrift V1 and Kerberos
There have been a few [posts](http://grokbase.com/p/cloudera/cdh-user/133pgawryt/hbase-thrift-with-kerberos-appears-to-ignore-keytab) about getting the HBase Thrift V1 server to work properly with Kerberos. In many cases, the solution was to merge keytabs for the HTTP principal and the HBase server principal. The other solution was to add the HTTP principal as a proxy user. Both of these solutions require extra work that isn't necessary. The HTTP principal should only be used for authenticating SPNEGO. The HBase server principal should be used to authenticate with the rest of HBase. I found this out after comparing the Apache Hive HiveServer2 thrift implementation with the HBase thrift server implementation. 

### Improving the HBase Thrift V1 Implementation
I emailed the [hbase-user mailing list](http://mail-archives.apache.org/mod_mbox/hbase-user/201801.mbox/%3CCAJU9nmh5YtZ%2BmAQSLo91yKm8pRVzAPNLBU9vdVMCcxHRtRqgoA%40mail.gmail.com%3E) to see if my findings were plausible or if I was missing something. Josh Elser reviewed it and said that this change would be useful. I opened [HBASE-19852](https://issues.apache.org/jira/browse/HBASE-19852) and put together a working patch over the next few months. It turns out the quick patch for our environment took some effort to contribute back to Apache HBase proper. The patch accomplished the following:

* Avoid the existing 401 try/catch block by checking the authorization header up front before checking for Kerberos credentials
* Add `hbase.thrift.spnego.principal` and `hbase.thrift.spnego.keytab.file` to allow configuring the SPNEGO principal specifically for the Thrift server

With the first change, this prevents the logs from being filled with messages about failing Kerberos authentication when the authorization header is empty. The second change allows the SPNEGO principal to be configured in the hbase-site.xml file. The thrift server will then be configured to use the SPNEGO principal and keytab for HTTP authentication. This prevents the need to merge keytabs and allows an administrator to use existing SPNEGO principals and keytabs that are on the host (like one setup by Ambari).

### Conclusion
[HBASE-19852](https://issues.apache.org/jira/browse/HBASE-19852) was reviewed and merged in June 2018. It is a part of HBase 2.1.0 and greater. The Apache HBase community was great to work with since they were patient while I worked on the patch over a few months. The new configuration options allows the HBase Thrift V1 server to work seemlessly with Kerberos and Hue. There is no longer a need to merge keytabs or perform other workarounds. This change has been in use for over a year now with success using the Hue HBase Browser with HBase and Kerberos. 

