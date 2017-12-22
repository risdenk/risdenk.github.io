---
title: "Elasticsearch, HDFS Snapshot Repository, Java SecurityManager, and Kerberos"
date: 2017-12-23 18:00:00 Z
layout: post
tags: bigdata elasticsearch hdfs hadoop java security manager kerberos snapshot elastic
---

### Overview
[Elasticsearch](https://www.elastic.co/products/elasticsearch/) is a distributed REST server on top of [Apache Lucene](https://lucene.apache.org/). It provides the ability to quickly index, analyze, and search data. [Elastic](https://www.elastic.co/), the company behind Elasticsearch, takes a few things very seriously:

* Ease of use
* Testing
* Security

For ease of use, Elasticsearch makes it simple to get up and running quickly without any trouble. For testing, Elasticsearch features all require tests to ensure that bugs are not reintroduced later. For security, [since Elasticsearch 5.0](https://www.elastic.co/guide/en/elasticsearch/reference/5.0/modules-scripting-security.html#java-security-manager) the [Java SecurityManager](https://docs.oracle.com/javase/7/docs/api/java/lang/SecurityManager.html) is on by default and cannot be disabled. Each of these play a role in ensuring that Elasticsearch continues to be a reliable platform.

One feature that is key to Elasticsearch being a reliable platform is the ability to [snapshot and restore](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/modules-snapshots.html) data successfully. This can be useful for moving between environments, preventing data loss, and even for testing. The ability to store snapshots on [HDFS](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html) works well for us since we can share this single repository amongst different clusters and nodes easily. Tying together testing and security with the HDFS snapshot repository resulted in a few interesting issues.

### HDFS Snapshot Repository and Kerberos
The Elasticsearch HDFS Snapshot Repository provides the ability to store snapshots directly on HDFS. HDFS in this case acts like a distributed file system. For Elasticsearch 5.0, the HDFS Snapshot Repository was moved from a separate Elastic project into Elasticsearch proper but was still a plugin. This made it much easier to configure Elasticsearch with the HDFS Snapshot Repository. It also ensured that testing and security were a top priority even for the HDFS Snapshot Repository.

In Elasticsearch 2.x, the HDFS Snapshot Repository was not compatible with the Java SecurityManager and caused many headaches if you wanted Elasticsearch to be secure and use HDFS for snapshots. Elasticsearch 5.x+ made it possible to have both configured. 

### Improving the HDFS Snapshot Repository with Kerberos
As we upgraded from Elasticsearch 2.4 to Elasticsearch 5.5, we noticed that there were some permissions missing with the Java SecurityManager policy when it came to the HDFS Snapshot Repository. I worked to debug where this was coming from and ran into two issues. I opened an issue with both [Elastic Support](https://www.elastic.co/support/welcome) and on the public [Elasticsearch Github](https://github.com/elastic/elasticsearch).

#### SLF4J for Hadoop logging with HDFS Snapshot Repository
The first issue was around logging for the HDFS Snapshot Repository. Having worked with HDFS before, I knew there should be more logging but Elasticsearch was swallowing these errors. I was able to work around this by explictly adding an SLF4J binding to ensure that HDFS logs could be configured in Elasticsearch. This turned into [issue #26512](https://github.com/elastic/elasticsearch/issues/26512) and was merged quickly. I was now able to configure logging for Hadoop to figure out the underlying permissison issues.

#### `suppressAccessChecks` error with readonly HDFS Snapshot Repository
The second issue, [issue #26513](https://github.com/elastic/elasticsearch/issues/26513) revolved around Java SecurityManager permissions with HDFS and Kerberos. Even though the plugin seemed to account for this use case, the stack trace was evidence that something was wrong. @jasontedor quickly triaged this and handed off to @jbaiera. It was determined that maybe [issue #22793](https://github.com/elastic/elasticsearch/pull/22793), which addressed other permission issues, could fix the problem. However to move forward, I had to come up with a reproducible test case. After some time, I was able to create a reproducible test case which focused around read only HDFS snapshot repositories. This use case was not tested with the existing test framework and once added it was possible to show that more permissions had to be granted. @jbaiera worked on a fix and this was included in 5.5.4, 5.6.2, and 6.0.0.

#### HDFS High Availability and HDFS Snapshot Repository
We upgraded from 5.5.2 to 5.6.2 pretty soon after it was released. We were able to remove the `suppressAccessChecks` work around Java SecurityManager policy we had put in place. Unfortunately, we found that there were again stack traces with Java security exceptions. I opened [issue 26868](https://github.com/elastic/elasticsearch/issues/26868) to work through the problem of tracking this down. After some digging, I was able to determine that the [HDFS High Availability](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithNFS.html) with multiple NameNodes was the cause. The test framework only used a single HDFS NameNode and the resulting Java SecurityManager policies were not correct. @jbaiera spent a lot of time to improve the Elasticsearch test framework to handle HDFS High Availabilty. He put up [PR #27196](https://github.com/elastic/elasticsearch/pull/27196) and I worked with him to ensure it was correct. After some initial issues, I was able to confirm that the great work of @jbaiera made the HDFS snapshot repository work with HDFS High Availability. This was merged recently and will be available in the following Elasticsearch versions: 5.5.6, 6.0.2, and 6.1.0.

### Where do we go from here?
Once Elasticsearch 5.5.6 is released, we will upgrade to it and test the HDFS snapshot repository with our workarounds removed. We will also be testing against Elasticsearch 6.x shortly and hopefully catch bugs sooner before they affect others. It has been a learning experience to debug some low level Kerberos and Java SecurityManager interactions. A big shoutout to @jbaiera from Elastic who has put a lot of the leg work into fixing the issues identified.

