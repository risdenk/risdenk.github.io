---
title: Apache Solr - Getting Involved - Two Year Anniversary
date: 2018-03-19 13:00:00 -05:00
tags:
- bigdata
- apache
- solr
- JDBC
- getting
- involved
layout: post
---

#### March 2018 Update
I originally posted this content to LinkedIn [here](https://www.linkedin.com/pulse/apache-solr-jdbc-how-get-involved-kevin-risden/) in May 2016. Cross posting to my blog with minor edits on the ~2 year anniversary of the [announcement](http://mail-archives.apache.org/mod_mbox/lucene-dev/201603.mbox/%3CCAE4tqLPcNwyJpsD8UBUJ67-52TVWDq-GY7H1Bk8_C1RO_7KFgA@mail.gmail.com%3E) of me becoming an [Apache Lucene/Solr](https://lucene.apache.org/solr/) committer.

### Overview
My [previous post](/2018/03/18/apache-solr-jdbc-tools-two-year-anniversary.html) in my Apache Solr JDBC blog series showed how to connect JDBC tools like [Apache Zeppelin](https://zeppelin.apache.org/) to [Apache Solr](https://lucene.apache.org/solr/). This post describes how you can get involved with Apache Solr and the JDBC driver. This post was inspired by the great [Lucidworks](https://lucidworks.com/) blog post by [Hoss](https://lucidworks.com/blog/?a_name=hossman) about the [14 ways to contribute to Apache Solr](https://lucidworks.com/2012/03/26/14-ways-to-contribute-to-solr/).

### Improving the Documentation
The [Apache Solr Reference Guide](https://lucene.apache.org/solr/guide/) contains information about how to use Parallel SQL and the JDBC driver to connect to Apache Solr. Documentation can always be improved to reduce the amount of time to get started. If there is anything that should be improved in the [reference guide](https://lucene.apache.org/solr/guide/), leave a comment on the specific page and it will be reviewed.

In addition to the reference guide, here are some references that can be used to get started with Parallel SQL and the JDBC driver:

* [Apache Solr JDBC - Introduction - Kevin Risden](/2018/03/17/apache-solr-jdbc-introduction-two-year-anniversary.html)
* [Apache Solr JDBC - Java - Sematext](https://sematext.com/blog/solr-6-as-jdbc-data-source/)
* [Apache Solr JDBC - JDBC Tools - Kevin Risden](/2018/03/18/apache-solr-jdbc-tools-two-year-anniversary.html)

### Asking Questions & Reporting Bugs/Improvements
If you have questions or would like to report any bugs you run across, the Apache Solr has a section on [Community](https://lucene.apache.org/solr/community.html) and how to use the solr-user mailing list. The solr-user mailing list is monitored by committers and users so you can get an answer quickly. Providing details and searching before asking can [improve your experience](http://www.catb.org/esr/faqs/smart-questions.html) with the mailing list. Once a bug or improvement has been vetted, it is typically entered into the [Apache JIRA](https://issues.apache.org/jira/).

### Helping with Development
In addition to documentation, contributing back code and patches to Apache Solr can be a way to give back. Apache Solr has a [How to Contribute](https://wiki.apache.org/solr/HowToContribute) guide that outlines where to get started. Apache Solr is written in Java and is open source. The development tasks are stored on [Apache JIRA](https://issues.apache.org/jira/) and allow developers to see what needs to be improved. Looking through JIRA and finding an issue that you are interested in is a great way to get started. The next step is to ensure the issue is reproducible or provide a patch with tests that solves the problem. A committer can then review the patch and commit it. The Apache Solr [Community](https://lucene.apache.org/solr/community.html) page has information about the solr-dev list which is used specifically for contributors to the Apache Solr code base.

A few of the relevant Apache Solr JIRAs for Parallel SQL and JDBC are:

* [SOLR-8125 - Umbrella ticket for Streaming & SQL issues](https://issues.apache.org/jira/browse/SOLR-8125)
* [SOLR-8659 - Improve JDBC driver for more SQL clients](https://issues.apache.org/jira/browse/SOLR-8659)
* [SOLR-8593 - Apache Calcite optimizer](https://issues.apache.org/jira/browse/SOLR-8593)

### Conclusion
I’ve given a peek into how I became an Apache Solr committer, an introduction to the Apache Solr JDBC driver, and some step-by-step guides on how to use the Apache Solr JDBC driver. If you are interested definitely feel free to get involved by follwing some of this tips described above.

