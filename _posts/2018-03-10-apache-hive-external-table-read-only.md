---
title: Apache Hive - External Table Read Only
date: 2018-03-10 12:00:00 -06:00
tags:
- bigdata
- apache
- hive
- external
- table
- read only
- security
layout: post
---

### Overview
[Apache Hive](https://hive.apache.org/) is a SQL abstraction on top of [Apache Hadoop HDFS](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html). It has the concept of databases and tables to organize data. Hive supports authorization which can restrict users from access certain databases and tables. HDFS also supports authorization to ensure data is only accessed by allowed users.

### Need for Hive External Table Read Only
We use HDFS authorization with [Apache Ranger]() to handle security policies. These security policies allow for read/write access to certain data and read only access to other data sets. We want to be able to have users create their own Hive tables over read only data. There are cases where multiple Hive tables over the same HDFS data makes sense (ie: custom deserializers). Currently, Apache Hive doesn't allow a user to create an external table without having read/write/execute to the underlying HDFS directory.

### Work around for Hive External Table Read Only
As a work around, we have created the Hive tables as a super user that has access to the underlying HDFS directory. The user who queries the Hive table only has read access to the underlying data so this works as expected. The downside is that administrators need to create tables for users which is clunky.

### What is next?
[HIVE-335] was created back in March 2009 with a request to be able to create Hive External Tables that are Read Only. We would love to see more focus placed on this to permit this type of table creation.

