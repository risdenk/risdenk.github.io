---
title: Apache Solr - JDBC Introduction - Two Year Anniversary
date: 2018-03-17 12:00:00 -06:00
tags:
- bigdata
- apache
- solr
- JDBC
- introduction
layout: post
---

#### March 2018 Update
I originally posted this content to LinkedIn [here](https://www.linkedin.com/pulse/apache-solr-jdbc-introduction-kevin-risden/) in April 2016. Cross posting to my blog later with minor edits on the ~2 year anniversary of the [announcement](http://mail-archives.apache.org/mod_mbox/lucene-dev/201603.mbox/%3CCAE4tqLPcNwyJpsD8UBUJ67-52TVWDq-GY7H1Bk8_C1RO_7KFgA@mail.gmail.com%3E) of me becoming an [Apache Lucene/Solr](https://lucene.apache.org/solr/) committer.

<br />

*In my [previous post](/2018/03/16/journey-to-apache-lucene-solr-commiter-two-year-anniversary.html), I detailed the history that led up to my working on the Apache Solr JDBC driver and becoming an Apache Lucene/Solr committer. This post will describe the Solr JDBC driver and its usage. The next few posts will be detailed guides on how to use the Solr JDBC driver with SQL clients and database visualization tools.*

### Overview
The first reference I could find of [Apache Solr](https://lucene.apache.org/solr/) and JDBC dates back to 2008 with [SOLR-373](https://issues.apache.org/jira/browse/SOLR-373). Even though it took almost 8 years, the Solr JDBC driver is a new feature of Solr 6 that enables JDBC connectivity to a Solr Cloud cluster. By opening Solr up to SQL queries, this enables more developers to access the power of a full text search engine for analytics without learning a new query language. JDBC opens up not only Java applications to query Solr with SQL, but also a variety of business intelligence (BI) tools.

The Solr JDBC driver builds on Solr Parallel SQL that was introduced by [Joel Bernstein](https://www.linkedin.com/in/bernsteinjoel/) in [SOLR-7560](https://issues.apache.org/jira/browse/SOLR-7560) and included the ability to handle SQL queries with the `/sql` handler. Joel also developed the initial Solr JDBC driver in [SOLR-7986](https://issues.apache.org/jira/browse/SOLR-7986). I improved the Solr JDBC driver to support some BI tools with [SOLR-8502](https://issues.apache.org/jira/browse/SOLR-8502). Although the Solr JDBC driver isn’t complete, it now supports tools like [DbVisualizer](https://www.dbvis.com/) and there is already work to support more in [SOLR-8659](https://issues.apache.org/jira/browse/SOLR-8659). With the first release of the Solr JDBC driver, only a subset of the SQL language is supported as detailed in the [Solr Parallel SQL reference guide](https://lucene.apache.org/solr/guide/7_2/parallel-sql-interface.html). A [SQL optimizer](https://issues.apache.org/jira/browse/SOLR-8593) has been added and join capabilities are planned for future releases.

### Getting Started
The Solr JDBC driver is easy to get started with, requiring a Solr Cloud cluster and a few jars on the client classpath. Currently the setup of the Solr JDBC driver requires either a Maven dependency `org.apache.solr:solr-solrj` or copying the following jars from the extracted Apache Solr binary archive to the client classpath:

* `dist/solr-solrj-${SOLR_VERSION}.jar`
* `dist/solrj-lib/*.jar`
* `commons-io-2.4.jar`
* `httpclient-4.4.1.jar`
* `httpcore-4.4.1.jar`
* `httpmime-4.4.1.jar`
* `jcl-over-slf4j-1.7.7.jar`
* `noggit-0.6.jar`
* `slf4j-api-1.7.7.jar`
* `stax2-api-3.1.4.jar`
* `woodstox-core-asl-4.4.1.jar`
* `zookeeper-3.4.6.jar`

**Note**: [SOLR-8680](https://issues.apache.org/jira/browse/SOLR-8680) was created to try to make this a single jar

Once these jars are on the client classpath, one can connect over JDBC with the following connection string format using the driver `org.apache.solr.client.solrj.io.sql.DriverImpl`:

```
jdbc:solr://SOLR_ZK_CONNECTION_STRING?collection=COLLECTION_NAME
```

An example of a connection string could be:

```
jdbc:solr://zk1,zk2,zk3:2181/solr?collection=collection1
```

The latest documentation for connecting over the Solr JDBC driver is available on the [Apache Solr Reference Guide Parallel SQL page](https://lucene.apache.org/solr/guide/7_2/parallel-sql-interface.html) under [Sending Queries JDBC](https://lucene.apache.org/solr/guide/7_2/parallel-sql-interface.html#sending-queries) and [SQL Clients and Database Visualization Tools](https://lucene.apache.org/solr/guide/7_2/parallel-sql-interface.html#sql-clients-and-database-visualization-tools). Additionally, [Sematext published a blog post](https://sematext.com/blog/solr-6-as-jdbc-data-source/) that describes in detail how to use Solr JDBC with Java. In some cases, the Solr collection will need to be [configured as detailed here](https://lucene.apache.org/solr/guide/6_6/parallel-sql-interface.html#configuration) to work with the Solr JDBC driver and Parallel SQL.

### SQL Clients and Database Visualization Tools
A few SQL clients and database visualization tools have been tested to work with the Solr JDBC driver. There are continuing efforts to expand the JDBC support to enable more clients under SOLR-8659. Below are a few screenshots of SQL tools connecting to Solr over the JDBC driver.

#### DbVisualizer
<p style="text-align:center"><a href="https://lucene.apache.org/solr/guide/7_2/solr-jdbc-dbvisualizer.html"><img width="800" src="/images/posts/2018-03-17/dbvisualizer_solr_jdbc.png" /></a></p>

#### SQuirrel SQL
<p style="text-align:center"><a href="https://lucene.apache.org/solr/guide/7_2/solr-jdbc-squirrel-sql.html"><img width="800" src="/images/posts/2018-03-17/squirrel_sql_solr_jdbc.png" /></a></p>

#### Apache Zeppelin
<p style="text-align:center"><a href="https://lucene.apache.org/solr/guide/7_2/solr-jdbc-apache-zeppelin.html"><img width="800" src="/images/posts/2018-03-17/apache_zeppelin_solr_jdbc.png" /></a></p>

### What is next?
I’ll be cross posting the original LinkedIn articles including some step by step guides on how to configure a few SQL clients and database visualization tools to connect to Solr over the JDBC driver. The [Apache Solr Reference Guide](https://lucene.apache.org/solr/guide/) has been updated to include more detail about connection parameters and some information about specific clients. If you have any questions about the Solr JDBC driver or want to help contribute, the [Apache Solr website](https://lucene.apache.org/solr/) has a section on [Community](https://lucene.apache.org/solr/community.html) and how to use the solr-user mailing list.

