---
title: Apache Knox - Audit Logging - Duplicate Correlation IDs
date: 2018-02-24 12:00:00 -06:00
tags:
- bigdata
- apache
- knox
- audit
- logging
- duplicate
- correlation
- id
layout: post
---

### Overview
[Apache Knox](https://knox.apache.org/) is a reverse proxy that simplifies security in front of a Kerberos secured [Apache Hadoop](https://hadoop.apache.org) cluster. Knox has the capability to audit the actions of users. Audit logging uses the concept of a [`correlation id`](https://blog.rapid7.com/2016/12/23/the-value-of-correlation-ids/) to track a single request through the system. The audit log fields are described [here](https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.1/bk_security/content/audit_log_files.html) with the `REQUEST_ID` containing the value of the `correlation id`. As part of debugging Knox interactions, we found that multiple requests had the same `correlation id` which should never happen. I [emailed the Apache Knox mailing list](https://mail-archives.apache.org/mod_mbox/knox-user/201710.mbox/%3CCAJU9nmifQR_D%3D9yVwbXVJ62VKqczZX8a4BedK6Dznwkk%3D1%2BnMw%40mail.gmail.com%3E) to determine if this was expected. The Knox community agreed this behavior was not correct and created [KNOX-1091](https://issues.apache.org/jira/browse/KNOX-1091).

### Determining how Knox `Correlation IDs` are generated
Apache Knox generates `correlation ids` using a Jetty handler. The [`CorrelationHandler`](https://github.com/apache/knox/blob/master/gateway-server/src/main/java/org/apache/knox/gateway/filter/CorrelationHandler.java#L37) sets the `RequestId` using `UUID.randomUUID()`. `UUID.randomUUID()` uses `SecureRandom` to generate a new string. In the auditing cases, the `UUID` doesn't have to be cryptographically secure but shouldn't generate duplicates easily. 

### Theories for duplicate `Correlation IDs`
I led my team through an exercise of brainstorming how Knox could be generating duplicate `correlation ids`. 

Some ideas we came up with:
* Java `UUID.randomUUID()` returning the same `UUID` under high load
* Jetty not thread safe under high load
* HTTP 1.1 pipelining requests handling
* LDAP integration cause 401 errors and duplicating requests
* Shiro not thread safe with session management
* Knox `CorrelationHander` not thread safe 

### Reproducing Duplicate `Correlation IDs`
I was able to reproduce duplicate `correlation ids` using [Apache Bench](https://httpd.apache.org/docs/2.4/programs/ab.html) when Knox didn't use authentication. I also determined that SSL did not change the behavior. Apache Knox 1.0.0 generated the following output for 1000 requests 100 concurrently.

```
[knox-1.0.0]$ grep -F access logs/gateway-audit.log | cut -d'|' -f3 | sort | uniq -c | sort -n | tail -n5
8 a781630c-93b8-48c2-a6fd-aaa428a6bf14
8 f0ab4c10-0dc7-41ef-a27a-9aebe9c8ce58
9 985df820-a82c-4704-b773-016769413cc2
43 b46b3f23-5514-401c-bfee-440790e54b31
95 73e77c01-054b-4063-8fd2-c1a3cabdfe4c
```

### Work around for Duplicate `Correlation IDs`
Setting `gateway.threadpool.max` to `6` in `gateway-site.xml`, I was able to prevent duplicate `correlation ids` from being generated. This prevents multiple requests from happening in parallel and therefore identifies this as a thread safe problem.

### Determining the Root Cause of Duplicate `Correlation IDs`
It looks like Log4j `Mapped Diagnostic Context` (`MDC`) is the middle piece that tries to hold the `correlation id`. I'm not convinced that `MDC` is being handled correctly with the Jetty threadpool. From what I gather threads being reused can cause issues with `MDC` if it is not cleaned out between uses. I don't see any places where `MDC.remove` or `MDC.clear` is called except in tests.

Some references:
* http://ashtonkemerling.com/blog/2017/09/01/mdc-and-threadpools/
* https://gquintana.github.io/2017/12/01/Structured-logging-with-SL-FJ-and-Logback.html

Apache Knox doesn't look like it is clearing the `MDC` between each request. The distribution of duplicate `correlation ids` correlates with how [Jetty prefers recently busy threads](https://github.com/eclipse/jetty.project/issues/2005#issuecomment-348679675).

### Where to go from here?
I have been looking at fixing the MDC handling in Apache Knox. The MDC needs to be cleared after each request and before a new request is handled. This will take some time to generate a test that will prevent a regression. Follow [KNOX-1091](https://issues.apache.org/jira/browse/KNOX-1091) for continued updates.

