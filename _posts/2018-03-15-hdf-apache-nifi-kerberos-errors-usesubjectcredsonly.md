---
title: HDF - Apache NiFi - Kerberos Errors and useSubjectCredsOnly
date: 2018-03-15 13:00:00 -05:00
tags:
- bigdata
- hdf
- apache
- nifi
- kerberos
- errors
- GSSException
- useSubjectCredsOnly
- security
layout: post
---

### Overview
My team supports [Hortonworks Data Flow (HDF)](https://hortonworks.com/products/data-platforms/hdf/) for a variety of streaming use cases. One of the core components of HDF is [Apache NiFi](https://nifi.apache.org/). Both HDF and our [Hortonworks Data Platform (HDP)](https://hortonworks.com/products/data-platforms/hdp/) are secured by [Kerberos](https://web.mit.edu/kerberos/). Kerberos security ensures that the user is authenticated before accessing a resource. We had a few issues that we could not nail down what the root cause was. One issue was when we would try to [stop a NiFi processor it would get a stuck thread](https://community.hortonworks.com/questions/155101/nifi-puthdfs-processor-stuck-and-not-able-to-relea.html) and not release until we restarted that NiFi node. Another issue was that we would get `GSSException` errors intermittently that would resolve themselves overtime. Both of these pointed to Kerberos since they would only happen on processors like HDFS, Hive, and HBase.

### Debugging Stuck Thread and `GSSException` Errors
We opened a support ticket with [Hortonworks](https://hortonworks.com/) in September 2017 to attempt to find the root cause of these errors. We had tried to eliminate all external variables on our side, but could not rule out Active Directory Kerberos changes. When the problem first started occurring, we were on HDF 2.x and we were informed that HDF 3.0 would fix these Kerberos related errors. After upgrading to HDF 3.0, the same errors occurred which concerned us.

We had noticed that other users of HDF were experiencing the same problems like [stuck threads](https://community.hortonworks.com/questions/155101/nifi-puthdfs-processor-stuck-and-not-able-to-relea.html). I pushed Hortonworks to try to find the root cause of these issue. In January 2018, we were put in touch with @joewitt one of the creators of [Apache NiFi](https://nifi.apache.org/) who informed us they were working very hard to reproduce the issue. Up to this point we had provided lots of logs to Hortonworks with a variety of debug settings to see if we could find the problem.

### Fixing Kerberos Related Errors
In January 2018, Hortonworks had a breakthrough that determined the root cause of the Kerberos issues with the help of @joshelser. The stuck thread issue turned out to be [NIFI-4318](https://issues.apache.org/jira/browse/NIFI-4318) which described that `javax.security.auth.useSubjectCredsOnly` must always be set to true. If `javax.security.auth.useSubjectCredsOnly` is not set to true, then processors that use Kerberos can hang due to a stuck thread waiting for the authentication prompt. We set `javax.security.auth.useSubjectCredsOnly` in our NiFi `bootstrap.conf`. You can check if `javax.security.auth.useSubjectCredsOnly` is being set to false with the following command:

```bash
sudo -u nifi /usr/jdk64/jdk1.8.0_112/bin/jinfo NIFI_PID | grep javax.security.auth.useSubjectCredsOnly
```

It turns out this was part of the issue since the `GSSExceptions` continued to occur. We were able to reduce some of the `GSSExceptions` by adjusting the relogin period for Kerberos processors as described in [NIFI-4350](https://issues.apache.org/jira/browse/NIFI-4350). The default relogin period is too long and was causing Kerberos ticket expirations resulting in `GSSExceptions`.

The remaining `GSSExceptions` were caused by Apache NiFi using [`UserGroupInformation` (UGI)](http://hadoop.apache.org/docs/stable/api/org/apache/hadoop/security/UserGroupInformation.html) in a non thread safe manner. [NIFI-4323](https://issues.apache.org/jira/browse/NIFI-4323) has all the gory details where many of the above mentioned issues are fixed permantently. [PR 2360](https://github.com/apache/nifi/pull/2360) shows all the code changes that went in to making this happen. [NIFI-4323](https://issues.apache.org/jira/browse/NIFI-4323) was merged into [Apache NiFi](https://nifi.apache.org/) 1.5.0 and picked up by HDF 3.1.0.

### Conclusion
If you are using [Hortonworks Data Flow (HDF)](https://hortonworks.com/products/data-platforms/hdf/) or [Apache Nifi](https://nifi.apache.org/) with a Kerberos secured Hadoop cluster, then you should upgrade to HDF 3.1.0 or Apache NiFi 1.5.0. [Apache Ambari](https://ambari.apache.org) management of HDF 3.1 will add the required properies to `bootstrap.conf` as well. We haven't fully verified all of our use cases on HDF 3.1 yet, but so far the results have been promising.

