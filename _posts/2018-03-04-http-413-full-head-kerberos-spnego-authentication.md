---
title: HTTP 413 Full HEAD - Kerberos SPNEGO authentication
date: 2018-03-04 12:00:00 -06:00
tags:
- kerberos
- spnego
- authentication
- 413
- HEAD
- jetty
- header
- size
- AD
- active directory
- groups
- security
layout: post
---

### Overview
[Kerberos](https://web.mit.edu/kerberos/) is a scary topic for many people who have had to deal with setting up or debugging it. [`SPNEGO` authentication](https://en.wikipedia.org/wiki/SPNEGO) is an area related to Kerberos that can cause a significant amount of headaches to setup and debug. @steveloughran has written an [ebook](https://steveloughran.gitbooks.io/kerberos_and_hadoop/) that highlights a few of these challenges. I have also written an [ebook](https://risdenk.gitbooks.io/hadoop_book/) with some code examples for dealing with Kerberos.

### `HTTP 413 Full HEAD` and `SPNEGO` authentication
The `HTTP 413 Full HEAD` error happens when the header is too large to be handled by the underlying server. The underlying server rejects the request returning the HTTP 413 error code.

This error comes up quite a bit across the Hadoop ecosystem with `SPNEGO` authentication. By default Jetty has a header limit of 8KB and this is too small to handle [Active Directory (AD) authentication headers](https://support.microsoft.com/en-us/help/327825/problems-with-kerberos-authentication-when-a-user-belongs-to-many-grou). The issue is that an AD user with a large number of groups increases the header size. The fix is to increase the default header size limit in Jetty. Many projects decided to increase this header limit to 64KB to avoid further issues.

A list of Hadoop related projects that have hit and fixed the `HTTP 413 Full HEAD` error:
* [HADOOP-8816](https://issues.apache.org/jira/browse/HADOOP-8816)
* [STORM-633](https://issues.apache.org/jira/browse/STORM-633)
* [HIVE-11720](https://issues.apache.org/jira/browse/HIVE-11720)
* [SPARK-15090](https://issues.apache.org/jira/browse/SPARK-15090)
* [CALCITE-2086](https://issues.apache.org/jira/browse/CALCITE-2086)

There are many Hadoop deployments that could be affected by this if they have the following conditions:
* Active Directory for Kerberos authentication
* Users with large number of groups
* Jetty web service with default header size

Although many of the popular Hadoop related projects have fixed this issue, it continues to come up with new projects not accounting for the header size with `SPNEGO` authentication.

