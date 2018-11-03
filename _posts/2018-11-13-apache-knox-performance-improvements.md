---
title: Apache Knox - Performance Improvements
date: 2018-11-13 08:00:00 -06:00
tags:
- bigdata
- apache
- knox
- security
- performance
- improvement
- hadoop
- hdfs
- webhdfs
- hbase
- hive
layout: post
---

### TL;DR
Apache Knox 1.2.0 should significantly improve:
* [Apache Hadoop WebHDFS](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/WebHDFS.html) write performance due to [KNOX-1521](https://issues.apache.org/jira/browse/KNOX-1521)
* [Apache Hive](https://hive.apache.org/) and GZip performance due to [KNOX-1530](https://issues.apache.org/jira/browse/KNOX-1530)

If you are using Java for TLS, then you should read [here](#java---tlsssl-performance).

### Overview
[Apache Knox](https://knox.apache.org/) is a reverse proxy that simplifies security in front of a Kerberos secured [Apache Hadoop](https://hadoop.apache.org/) cluster and other related components. On the [knox-user mailing list](https://mail-archives.apache.org/mod_mbox/knox-user/201809.mbox/%3CCACEuXj475wey-AzxO%2Bqf162Qe7ChEB8oNj1Hd6O1E4VNd8cH7g%40mail.gmail.com%3E) and [Knox Jira](https://issues.apache.org/jira/browse/KNOX-1221), there have been reports about Apache Knox not performing as expected. Two of the reported cases focused on [Apache Hadoop WebHDFS](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/WebHDFS.html) performance specifically. I was able to reproduce the slow downs with Apache Knox although the findings were surprising. This blog details the performance findings as well as improvements that will be in Apache Knox 1.2.0.

### Reproducing the performance issues
#### Apache Hadoop - WebHDFS
I started looking into the two reported WebHDFS performance issues ([KNOX-1221](https://issues.apache.org/jira/browse/KNOX-1221) and [knox-user post](https://mail-archives.apache.org/mod_mbox/knox-user/201809.mbox/%3CCACEuXj475wey-AzxO%2Bqf162Qe7ChEB8oNj1Hd6O1E4VNd8cH7g%40mail.gmail.com%3E)). I found that the issue reproduced easily on a VM on my laptop. I tested read and write performance of WebHDFS natively with curl as well as going through Apache Knox. The results as posted to [KNOX-1221](https://issues.apache.org/jira/browse/KNOX-1221) were as follows:

**WebHDFS Read Performance - 1GB file**

| Test Case            | Transfer Speed | Time |
|----------------------|----------------|------|
| Native WebHDFS       | 252 MB/s       | 3.8s |
| Knox w/o TLS         | 264 MB/s       | 3.6s |
| Knox w/ TLS          | 54 MB/s        | 20s  |
| Parallel Knox w/ TLS | 2 at ~48MB/s   | 22s  |

**WebHDFS Write Performance - 1GB file**

| Test Case            | Time |
|----------------------|------|
| Native WebHDFS       | 2.6s |
| Knox w/o TLS         | 29s  |
| Knox w/ TLS          | 50s  |

The results were very surprising since the numbers were all over the board. What was consistent was that Knox performance was poor for reading with TLS and writing regardless of TLS. Another interesting finding was that parallel reads from Knox did not slow down, but instead each connection was limited independently. Details of the analysis are found below [here](#apache-hadoop---webhdfs-1).

#### Apache HBase - HBase Rest
After analyzing WebHDFS performance, I decided to look into other services to see if the same performance slowdowns existed. I looked at Apache HBase Rest as part of [KNOX-1524](https://issues.apache.org/jira/browse/KNOX-1525). I decided to test without TLS for Knox since there was a slowdown identified as part of WebHDFS already. 

**Scan Performance for 100 thousand rows**

| Test Case           | Time  |
|---------------------|-------|
| HBase shell         | 13.9s |
| HBase Rest - native | 3.4s  |
| HBase Rest - Knox   | 3.7s  |

The results were not too surprising. More details of the analysis are found below [here](#apache-hbase---hbase-rest-1).

#### Apache Hive - HiveServer2
I also looked into HiveServer2 performance with and without Apache Knox as part of [KNOX-1524](https://issues.apache.org/jira/browse/KNOX-1524). The testing below is again without TLS.

**Select \* performance for 200 thousand rows**

| Test Case                         | Time |
|-----------------------------------|------|
| hdfs dfs -text                    | 2.4s |
| beeline binary fetchSize=1000     | 6.2s |
| beeline http fetchSize=1000       | 7.5s |
| beeline http Knox fetchSize=1000  | 9.9s |
| beeline binary fetchSize=10000    | 7.3s | 
| beeline http fetchSize=10000      | 7.9s |
| beeline http Knox fetchSize=10000 | 8.5s |

This showed there was room for improvement for Hive with Knox as well. Details of the analysis are found below [here](#apache-hive---hiveserver2-1).

### Performance Analysis
#### Apache Hadoop - WebHDFS
While lookg at the WebHDFS results, I found that disabling TLS resulted in a big performance gain. Since changing `ssl.enabled` in `gateway-site.xml` was the only change, that meant that TLS was the only factor for read performance differences. I looked into Jetty performance with TLS and found there were known performance issues with the JDK. For more details, see below [here](#java---tlsssl-performance).

The WebHDFS write performance difference could not be attributed to TLS performance since non TLS Knox was also ~20 seconds slower. I experimented with different buffersizes and upgrading httpclient before finding the root cause. The performance difference can be attributed to an issue with the `UrlRewriteRequestStream` in Apache Knox. There are multiple read methods on an `InputStream` and those were not implemented. For the fix details, see below [here](#knox---webhdfs-write-performance).

#### Apache HBase - HBase Rest
The [HBase shell](https://hbase.apache.org/book.html#shell) slowness is to be expected since it is written in [JRuby](https://www.jruby.org/) and not the best tool for working with HBase. Typically the [HBase Java API](https://hbase.apache.org/book.html#hbase_apis) is used. While looking at the results, there were no big bottlenecks that jumped out from the performance test. There is some overhead due to Apache Knox but much of this is due to the extra hops.

#### Apache Hive - HiveServer2
It took me a few tries to create a test framework that would allow be to test the changes easily. One of the big findings was that Hive is significantly slower than `hdfs dfs -text` for the same file. There can be some performance improvements to HiveServer2 itself. Another finding is that HiveServer2 binary vs http modes differed significantly with the default `fetchSize` of 1000. My guess is that when HTTP compression was added in [HIVE-17194](https://issues.apache.org/jira/browse/HIVE-17194), the `fetchSize` parameter should have been increased to improve over the wire efficiency. When ignoring the binary mode performance, there was still a difference between HiveServer2 http mode with and without Apache Knox. Details on the performance improvements can be found [here](#knox---gzip-handling).

### Performance Improvements
#### Java - TLS/SSL Performance
There are some performance issues when using the default JDK TLS implementation. I found a few references about the JDK and Jetty. 

* [https://nbsoftsolutions.com/blog/the-cost-of-tls-in-java-and-solutions](https://nbsoftsolutions.com/blog/the-cost-of-tls-in-java-and-solutions)
* [https://nbsoftsolutions.com/blog/dropwizard-1-3-upcoming-tls-improvements](https://nbsoftsolutions.com/blog/dropwizard-1-3-upcoming-tls-improvements)
* [https://webtide.com/conscrypting-native-ssl-for-jetty/](https://webtide.com/conscrypting-native-ssl-for-jetty/)

I was able to test with [Conscrypt](https://github.com/google/conscrypt/) and found that the performance slowdowns for TLS reads and writes went away. I also tested disabling GCM since there are references that GCM can cause performance issues with JDK 8.

* [https://www.wowza.com/docs/how-to-improve-ssl-performance-with-java-8](https://www.wowza.com/docs/how-to-improve-ssl-performance-with-java-8)
* [https://stackoverflow.com/questions/25992131/slow-aes-gcm-encryption-and-decryption-with-java-8u20](https://stackoverflow.com/questions/25992131/slow-aes-gcm-encryption-and-decryption-with-java-8u20)

The results of testing different TLS implementations are below:

| Test Case             | Transfer Speed | Time |
|-----------------------|----------------|------|
| Native WebHDFS        | 252MB/s        | 3.8s |
| Knox w/o TLS          | 264MB/s        | 3.6s |
| Knox w/ Conscrypt TLS | 245MB/s        | 4.2s |
| Knox w/ TLS no GCM    | 125MB/s        | 8.7s |
| Knox w/ TLS           | 54.3MB/s       | 20s  |

Switching to a different TLS implementation provider for the JDK can significantly help performance. This goes across the board for any TLS handling with Java. Another otpion is to terminate TLS connections with a non Java based load balancer. Finally, turning off TLS for performance specific isolated use cases may be ok. These options are ones that should be considered when using TLS with Java.

#### Knox - WebHDFS Write Performance
I created [KNOX-1521](https://issues.apache.org/jira/browse/KNOX-1521) to add the missing `read` methods on the `UrlRewriteRequestStream` class. This allows the underlying stream to read more efficiently than 1 byte at a time. With the changes from [KNOX=1521](https://issues.apache.org/jira/browse/KNOX-1521), WebHDFS write performance is now much closer to native WebHDFS. The updated write performance after [KNOX-1521](https://issues.apache.org/jira/browse/KNOX-1521) results are below:

**WebHDFS Write Performance - 1GB file - KNOX-1521**

| Test Case                  | Time |
|----------------------------|------|
| Native WebHDFS             | 3.3s |
| Knox w/o TLS               | 29s  |
| Knox w/o TLS w/ KNOX-1521  | 4.2s |

#### Knox - GZip Handling
I found that Apache Knox had a few issues when it came to handling GZip compressed data. I opened [KNOX-1530](https://issues.apache.org/jira/browse/KNOX-1530) to address the underlying issues. The big improvement being that Knox after [KNOX-1530](https://issues.apache.org/jira/browse/KNOX-1530) will not decompress data that doesn't need to be rewritten. This removes a lot of processing and should improvement Knox performance for other use cases like reading compressed files from WebHDFS and handling JS/CSS compressed files for UIs. After [KNOX-1530](https://issues.apache.org/jira/browse/KNOX-1530) was addressed, the [performance for Apache Hive HiveServer2 in http mode with and without Apache Knox](https://issues.apache.org/jira/browse/KNOX-1524?focusedCommentId=16673639&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-16673639) was about the same.

**Select \* performance for 200 thousand rows with [KNOX-1530](https://issues.apache.org/jira/browse/KNOX-1530)**

| Test Case                         | Time |
|-----------------------------------|------|
| hdfs dfs -text                    | 2.1s |
| beeline binary fetchSize=1000     | 5.4s |
| beeline http fetchSize=1000       | 6.8s |
| beeline http Knox fetchSize=1000  | 7.7s |
| beeline binary fetchSize=10000    | 6.8s | 
| beeline http fetchSize=10000      | 7.7s |
| beeline http Knox fetchSize=10000 | 7.8s |

The default `fetchSize` of 1000 slows down HTTP mode since there needs to be repeated requests to get more results.

### Conclusion
By reproducing the WebHDFS performance bottleneck, it showed that we could improve Knox performance. WebHDFS write performance for Apache Knox 1.2.0 should be significantly faster due to [KNOX-1521](https://issues.apache.org/jira/browse/KNOX-1521) changes. Hive perofrmance should be better in Apache Knox 1.2.0 due to [KNOX-1530](https://issues.apache.org/jira/browse/KNOX-1530) with better GZip handling. Apache Knox 1.2.0 should be released soon with these performance improvements and more.

I posted the performance tests I used [here](https://github.com/risdenk/knox-performance-tests) so they can be used to find other performance bottle The performance benchmarking should be reproducible and I will use them for more performance testing soon.

The performance testing done so far is for comparison against the native endpoint and not to show absolutely best performance numbers. This type of testing found some bottlenecks that have been addressed for Apache Knox 1.2.0. All of the tests done so far are without Kerberos authentication for the backend. There could be additional performance bottlenecks when Kerberos authentication is used and that will be another area I'll be looking into.

