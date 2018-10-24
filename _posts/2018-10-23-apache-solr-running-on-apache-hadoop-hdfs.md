---
title: Apache Solr - Running on Apache Hadoop HDFS
date: 2018-10-23 09:00:00 -05:00
tags:
- bigdata
- apache
- solr
- hadoop
- hdfs
- performance
- tuning
- best practice
layout: post
---

### Overview
[Apache Solr](https://lucene.apache.org/solr) is a full text search engine that is built on [Apache Lucene](https://lucene.apache.org/solr/). I've been working with Apache Solr for the past six years. Some of these were pure Solr installations, but many were integrated with [Apache Hadoop](https://hadoop.apache.org/). This includes both Hortonworks HDP Search as well as Cloudera Search. Performance for Solr on [HDFS](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html) is a common question so writing this post to help share some of my experience.

### Apache Hadoop HDFS
[Apache Hadoop](https://hadoop.apache.org/) contains a filesystem called [Hadoop Distributed File System (HDFS)](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html). HDFS is designed to scale to petabytes of data on commodity hardware. The definition of commodity hardware has changed over the years, but the premise is that the latest and greatest hardware is not needed. HDFS is used by a variety of workloads from [Apache HBase](https://hbase.apache.org/) to [Apache Spark](https://spark.apache.org/). Performance on HDFS tends to favor large files for both reading and writing. HDFS also uses all available disks for I/O which can be helpful for large clusters. 

### Apache Solr and HDFS
Apache Solr can run on HDFS since the early 4.x versions. [Cloudera Search](https://www.cloudera.com/products/open-source/apache-hadoop/apache-solr.html) added this capability to be able to use the existing HDFS storage for search. [Hortonworks HDP Search](https://hortonworks.com/blog/enterprise-search-hdp-search/), since it is based on Apache Solr, has support for HDFS as well. Since HDFS is not a local filesystem, Apache Solr implements a block cache that is designed to help cache HDFS blocks in memory. With the HDFS block cache for querying, Apache Solr can have slower but similar performance to local indices. The HDFS block cache is not used for merging, indexing, or read once use cases. This means that there are some areas where Apache Solr with HDFS can be slower.

### Apache Solr Performance
If you are looking for the best performance with the fewest variations, then SSDs and ample memory is where you should be looking. If you are budget constrained, then spinning disks with memory can also provide adequate performance. Solr on HDFS can perform just as well as local disks given the right amount of memory. The common "it depends" caveat will come down to the specific use case. For large scale analytics then Solr on HDFS performs well. For high speed indexing then you will need SSDs since the write performance of Solr on HDFS is not going to match.

Most of the time when dealing with performance issues with Solr, I found that it is not the underlying hardware to be the problem. Typically the way the data is indexed or queried can have a huge impact on performance. The standard debugging and improvements here help with all different types of hardware.

### Apache Solr on HDFS - Best Practices
#### Shutdown Apache Solr Cleanly
Make sure you give Apache Solr plenty of time to shutdown cleanly. Older versions of the `solr` script waited only 5 seconds before shutting down. Increase the sleep time to ensure that you do not leave `write.lock` files on HDFS from an unclean shutdown.

#### Ulimits must be configured correctly
Ensure that you have the proper ulimits for the user running Solr. It will cause huge issues when you can't use Solr due to ulimits that are too low.

#### Use a Zookeeper chroot
With Apache Hadoop, many different pieces of software use Zookeeper. It will help keep things organized if you use a chroot specifically for Solr.

#### Make a directory on HDFS for Solr
Make a directory on HDFS for Solr that isn't used for anything else. This will make sure you don't cause problems with other processes reading/writing from that location. It also makes it possible to set permissions to ensure only the Solr user has access.

#### HDFS Block Cache must be tuned
Ensure that the HDFS Block Cache is enabled and that it is tuned properly. By default the block cache does not have enough slabs for good performance. Each slab for the HDFS block cache is by default 128MB (`solr.hdfs.blockcache.blocksperbank`:16834 * 8KB). The number of slabs determines how much memory will be used for caching. Since the HDFS block cache is stored offheap, Java must also be allowed to allocate up to that amount of direct memory with `-XX:MaxDirectMemorySize`.

Here is a handy table to show relationship between number of slabs, MaxDirectMemorySize, and the HDFS block cache size.

|`-Dsolr.hdfs.blockcache.slab.count`|`-XX:MaxDirectMemorySize`|HDFS Block Cache Size|
|-----------------------------------|-------------------------|---------------------|
| 1                                 | 250MB                   | 128MB               |
| 8                                 | 2GB                     | 1GB                 |
| 20                                | 4GB                     | 2.5GB               |
| 40                                | 8GB                     | 5GB                 |
| 100                               | 15GB                    | 12.5GB              |
| 200                               | 30GB                    | 25GB                |

When configured correctly, Solr will print out a calculation of the memory required in the logs like so:

```
Block cache target memory usage, slab size of [134217728] will allocate [40] slabs and use ~[5368709120] bytes
```

#### Ensure that HDFS Short Circuit Reads are enabled
[HDFS Short Circuit Reads](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/ShortCircuitLocalReads.html) allow the HDFS library to read from a local socket instead of making a network call. This can significantly improve read performance.

#### Example Configuration
```
# Solr HDFS - setup
## Use HDFS by default for its collection data and tlogs
SOLR_OPTS="$SOLR_OPTS -Dsolr.directoryFactory=HdfsDirectoryFactory \
    -Dsolr.lock.type=hdfs \
    -Dsolr.hdfs.home=$(hdfs getconf -confKey fs.defaultFS)/apps/solr \
    -Dsolr.hdfs.confdir=/etc/hadoop/conf"

## If HDFS Kerberos enabled, uncomment the following
#SOLR_OPTS="$SOLR_OPTS -Dsolr.hdfs.security.kerberos.enabled=true \
#    -Dsolr.hdfs.security.kerberos.keytabfile=/etc/security/keytabs/solr.keytab \
#    -Dsolr.hdfs.security.kerberos.principal=solr@REALM"

# Solr HDFS - performance
## Enable the HDFS Block Cache to take the place of memory mapping files
SOLR_OPTS="$SOLR_OPTS -Dsolr.hdfs.blockcache.enabled=true \
    -Dsolr.hdfs.blockcache.global=true \
    -Dsolr.hdfs.blockcache.read.enabled=true \
    -Dsolr.hdfs.blockcache.write.enabled=false"

## Size the HDFS Block Cache
SOLR_OPTS="$SOLR_OPTS -Dsolr.hdfs.blockcache.blocksperbank=16384 \
    -Dsolr.hdfs.blockcache.slab.count=200"

## Enable direct memory allocation to allocate HDFS Block Cache off heap
SOLR_OPTS="$SOLR_OPTS -Dsolr.hdfs.blockcache.direct.memory.allocation=true \
    -XX:MaxDirectMemorySize=30g -XX:+UseLargePages"

## Enable HDFS Short Circuit reads if possible
### Note: This path is different for Cloudera. It must be the path to the HDFS native libraries
SOLR_OPTS="$SOLR_OPTS -Djava.library.path=:/usr/hdp/current/hadoop-client/lib/native/Linux-amd64-64:/usr/hdp/current/hadoop-client/lib/native"

## If Near Real Time (NRT) enable HDFS NRT caching directory, uncomment the following
#SOLR_OPTS="$SOLR_OPTS -Dsolr.hdfs.nrtcachingdirectory.enable=true \
#    -Dsolr.hdfs.nrtcachingdirectory.maxmergesizemb=16 \
#    -Dsolr.hdfs.nrtcachingdirectory.maxcachedmb=192"
```

### Conclusion
It is possible to get reasonable performance out of Apache Solr running on Apache Hadoop HDFS. If budget allows then SSDs will give better performance for both indexing and querying. Finally, given the proper amount of memory, even spinning disks will give adequate performance for Apache Solr.

#### References
* [https://wiki.apache.org/solr/SolrPerformanceProblems#SSD](https://wiki.apache.org/solr/SolrPerformanceProblems#SSD)
* [https://sbdevel.wordpress.com/2013/06/06/memory-is-overrated/](https://sbdevel.wordpress.com/2013/06/06/memory-is-overrated/)
* [https://community.hortonworks.com/questions/27567/write-performance-in-hdfs.html](https://community.hortonworks.com/questions/27567/write-performance-in-hdfs.html)
* [https://blog.cloudera.com/blog/2014/03/the-truth-about-mapreduce-performance-on-ssds/](https://blog.cloudera.com/blog/2014/03/the-truth-about-mapreduce-performance-on-ssds/)
* [https://community.hortonworks.com/questions/4858/solrcloud-performance-hdfs-indexdata.html](https://community.hortonworks.com/questions/4858/solrcloud-performance-hdfs-indexdata.html)
* [https://www.slideshare.net/lucidworks/solr-on-hdfs-final-mark-miller](https://www.slideshare.net/lucidworks/solr-on-hdfs-final-mark-miller)
* [https://issues.apache.org/jira/browse/SOLR-7393](https://issues.apache.org/jira/browse/SOLR-7393)
* [http://blog.cloudera.com/blog/2017/06/apache-solr-memory-tuning-for-production/](http://blog.cloudera.com/blog/2017/06/apache-solr-memory-tuning-for-production/)
* [http://blog.cloudera.com/blog/2017/06/solr-memory-tuning-for-production-part-2/](http://blog.cloudera.com/blog/2017/06/solr-memory-tuning-for-production-part-2/)
* [https://community.plm.automation.siemens.com/t5/Developer-Space/Running-Solr-on-S3/td-p/449360](https://community.plm.automation.siemens.com/t5/Developer-Space/Running-Solr-on-S3/td-p/449360)

