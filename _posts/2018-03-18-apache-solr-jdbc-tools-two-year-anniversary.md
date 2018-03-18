---
title: Apache Solr - JDBC Tools - Two Year Anniversary
date: 2018-03-18 12:00:00 -05:00
tags:
- bigdata
- apache
- solr
- JDBC
- tools
layout: post
---

#### March 2018 Update
I originally posted this content to LinkedIn [here](https://www.linkedin.com/pulse/apache-solr-jdbc-dbvisualizer-kevin-risden/), [here](https://www.linkedin.com/pulse/apache-solr-jdbc-squirrel-sql-kevin-risden/), and [here](https://www.linkedin.com/pulse/apache-solr-jdbc-zeppelin-incubating-kevin-risden/) in April-May 2016. Cross posting to my blog with edits on the ~2 year anniversary of the [announcement](http://mail-archives.apache.org/mod_mbox/lucene-dev/201603.mbox/%3CCAE4tqLPcNwyJpsD8UBUJ67-52TVWDq-GY7H1Bk8_C1RO_7KFgA@mail.gmail.com%3E) of me becoming an [Apache Lucene/Solr](https://lucene.apache.org/solr/) committer. This post combines the three original posts since the content has been migrated to the [Apache Solr Reference Guide](https://lucene.apache.org/solr/guide/).

### Overview
My [previous post](/2018/03/17/apache-solr-jdbc-introduction-two-year-anniversary.html) on Apache Solr JDBC gave an introduction of the feature and a sneak peak into some of the SQL clients and database visualization tools that can be connected to Apache Solr. This post highlights that you can connect [DbVisualizer](https://www.dbvis.com/), [SQuirreL SQL](https://squirrel-sql.sourceforge.net/), and [Apache Zeppelin](https://zeppelin.apache.org/) to Apache Solr using the Solr JDBC driver.

### DbVisualizer
[DbVisualizer](https://www.dbvis.com/) is a Java based database query and management tool. The step by step guide contains screenshots showing how to add the Apache Solr JDBC driver, make a connection to Solr, and then perform some SQL queries over Solr. This corresponds to the Apache Solr JIRA [SOLR-8521](https://issues.apache.org/jira/browse/SOLR-8521) and [Apache Solr Reference Guide page on DbVisualizer](https://lucene.apache.org/solr/guide/7_2/solr-jdbc-dbvisualizer.html).

### SQuirreL SQL
[SQuirreL SQL](https://squirrel-sql.sourceforge.net/) is a Java-based database query and management tool. The step by step guide contains screenshots showing how to add the Solr JDBC driver, add an alias for Solr, connect to Solr, and then perform some SQL queries over Solr. This corresponds to the Apache Solr JIRA [SOLR-8825](https://issues.apache.org/jira/browse/SOLR-8825) and [Apache Solr Reference Guide page on SQuirreL SQL](https://lucene.apache.org/solr/guide/7_2/solr-jdbc-squirrel-sql.html).

### Apache Zeppelin
[Apache Zeppelin](https://zeppelin.apache.org) is a web-based notebook that enables interactive data analytics. The step by step guide contains screenshots showing how to add the Apache Solr JDBC driver as an interpreter, use the interpreter in a notebook, and then perform some queries with the notebook. This corresponds to the Apache Solr JIRA [SOLR-8824](https://issues.apache.org/jira/browse/SOLR-8824) and [Apache Solr Reference Guide page on Apache Zeppelin](https://lucene.apache.org/solr/guide/7_2/solr-jdbc-apache-zeppelin.html).

