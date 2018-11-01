---
title: TODO - Apache Solr - Hadoop Authentication Plugin - LDAP
date: 2018-10-30 09:00:00 -05:00
tags:
- bigdata
- apache
- solr
- hadoop
- authentication
- security
- ldap
- configuration
layout: post
---

### Overview
[Apache Solr](https://lucene.apache.org/solr) is a full text search engine that is built on [Apache Lucene](https://lucene.apache.org/solr/). One of the questions I've been asked about in the past is LDAP support for Apache Solr authentication. While there are commercial additions that add LDAP support like [Lucidworks Fusion](), Apache Solr doesn't have an LDAP authentication plugin out of the box. 


fyi I checked the above and the ldap part of the hadoop-auth support came in Apache Hadoop 2.8.0 - https://issues.apache.org/jira/browse/HADOOP-12082. Solr only has Hadoop 2.7.4 packaged currently - https://github.com/apache/lucene-solr/blob/branch_7_5/lucene/ivy-versions.properties#L156. This means that when you try to configure the HadoopAuthenticationPlugin with ldap you get "Error initializing org.apache.solr.security.HadoopAuthPlugin: javax.servlet.ServletException: java.lang.ClassNotFoundException: ldap" since ldap isn't a known type.

### Conclusion


#### References
* https://lucene.apache.org/solr/guide/7_5/securing-solr.html
* https://lucene.apache.org/solr/guide/7_5/hadoop-authentication-plugin.html
* https://issues.apache.org/jira/browse/SOLR-9513
* https://stackoverflow.com/questions/50647431/ldap-integration-with-solr
* https://community.hortonworks.com/questions/130989/solr-ldap-integration.html
* https://github.com/apache/lucene-solr/blob/branch_7_5/lucene/ivy-versions.properties#L156
* https://issues.apache.org/jira/browse/HADOOP-12082

