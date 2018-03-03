---
title: My Journey to Apache Lucene/Solr Committer - Two Year Anniversary
date: 2018-03-16 13:00:00 -05:00
tags:
- bigdata
- apache
- lucene
- solr
- committer
- journey
layout: post
---

#### March 2018 Update
I originally posted this content to LinkedIn [here](https://www.linkedin.com/pulse/my-journey-apache-lucenesolr-committer-kevin-risden/) in April 2016. Cross posting to my blog with minor edits on the 2 year anniversary of the [announcement](http://mail-archives.apache.org/mod_mbox/lucene-dev/201603.mbox/%3CCAE4tqLPcNwyJpsD8UBUJ67-52TVWDq-GY7H1Bk8_C1RO_7KFgA@mail.gmail.com%3E) of me becoming an [Apache Lucene/Solr](https://lucene.apache.org/solr/) committer.

### Introduction
I worked for [Avalon Consulting, LLC](https://www.avalonconsult.com) from 2013-2017. I wrote this ~3 years after joining Avalon to relect on my time there and on becoming a Apache Lucene/Solr committer. My time at Avalon had been a whirlwind of technologies and projects with a focus on search and search with Hadoop. In this post I wanted to outline some of my experiences and what led to my contributing to [Apache Solr](https://lucene.apache.org/solr/) -- specifically the Solr JDBC driver.

### 2013 - Introduction to Solr and Hadoop
#### Spring 2013 - Joining Avalon Consulting, LLC
When I joined Avalon Consulting, LLC in January 2013, I was fortunate to immediately have two senior technical mentors: Sam and Ryan. Sam mentored me on search and Ryan guided me on big data and Hadoop. This early mentorship has shaped much of my career at Avalon since I have focused on search and Hadoop.

#### Spring 2013 - USP/USAP & Sam
Sam developed [USP (Unified Search Platform)](http://www.avalonconsult.com/unified-search-platform) and [USAP (Unified Search and Analytics Platform)](http://www.avalonconsult.com/usap). These were web applications designed to use search engines for analytics and finding insights about your data. Sam explained the rationale behind the two projects and how he thought that search would enable analytics. USP and USAP were used for a few projects and many demos at Avalon. Little did Sam know at the time, but USAP predated the now popular Elastic Kibana application.

#### Spring 2013 - Enron Email Demo & Ryan
Ryan completed a project with a large insurance company processing a billion emails before I joined Avalon. Around that same time, Avalon needed a way to show that we could process large data sets effectively. Ryan built a simple example using Amazon Elastic MapReduce and the Enron email data set. After I joined Avalon, I improved this example and added the USP/USAP interface on top of the Enron emails. This provided a great demo interface and showed that we could process lots of data quickly and still gain valuable insights.

Back in the spring of 2013, Lucidworks was interested in having multiple options for how to present their Apache Solr-based search platform, Lucidworks Search. Avalon offered our Enron email demo for this purpose and helped staff the Lucidworks booth at the 2013 Strata conference in San Jose. I spent the conference exhibiting the Enron email demo to a variety of conference attendees.

### 2013-2016 - Solr and Hadoop
#### Fall 2013 - Solr Cloud & HBase Indexer
In the fall of 2013, integrating search and Hadoop search was in its infancy. For a large telecommunications company, I was responsible for three use cases in which one was processing a large amount of full text. The existing solution used a custom search application based on Lucene, but the application wasn’t scaling to meet their needs. The client wanted to search the text for trends that could help them service customers more effectively. Hortonworks HDP 1.3 did not include a search engine in the distribution. I evaluated both Solr and Elasticsearch and made the decision to go with Solr for the project due to its more mature integration with Hadoop. At the time, Cloudera had already started putting Solr in their distribution with Cloudera Search. For this project, I integrated the NGData HBase Indexer and Solr to enable near real-time ingestion and search of the full text.

#### Fall 2014 - Spring 2015 - Kafka, Storm, HBase, and Solr
For the second time in about 3 years, Avalon helped the same insurance company migrate an existing legacy system to Hadoop. My colleague Trey and I worked on implementing a near real-time platform based on HDP for ingesting communication information. This project integrated many pieces of the Hadoop ecosystem to provide scale and speed for legal discovery purposes. This project integrated Solr and Hadoop so that this system could support the future growth expected of electronic communications. The scale required for this project also necessitated answering questions about how to reindex and query that were nontrivial to solve. The solution provided near real-time ingestion of documents which drastically improved upon the 8 hour lag of the legacy system.

#### Fall 2015 - Search and Hadoop
The fall of 2015 proved to be quite varied in the projects that I did especially around search and Hadoop. I worked with a startup on a pure search project in that they needed help specifically with Solr performance issues. I was able to improve the performance of ingestion and query by over 10x within a few days. A payment processing company wanted an architecture workshop of search and Hadoop. This overview showed that Hadoop wasn't the best fit in the short term, but that a search engine could be helpful for solving their analytics problems. The client settled on integrating Kafka and the ELK stack, which I was able to help get them started on. This included scaling suggestions as well as guidance on how to best use the technologies.

#### Spring 2016 - Cloudera Search (Solr) & CDH
The spring of 2016 brought me back to a manufacturing company where I had previously set up a Hortonworks HDP cluster. This time Avalon was integrating Cloudera CDH with their existing EDW to provide analytics with search. The client had an existing process for pulling in relational data from Teradata and Microsoft SQL Server to Hadoop and Cloudera Search, but it was slow and not automated. Avalon streamlined the process and provided guidance on how to best use Cloudera Search for analytics.

### Fall 2015 - Spring 2016 - Developing for Solr
After multiple projects related to search and following the Apache Solr community (JIRAs and the Solr mailing lists) for a few years, I wanted to contribute myself. There were a few events that happened in October 2015 that started me down the path to contribute.

[Erick Erickson](https://www.linkedin.com/in/erick-erickson-129a341) presented at an Avalon weekly meeting in October 2015 about Streaming Aggregations. I had read about streaming aggregations, but didn't know how much power they had. Erick Erickson’s presentation was the first event in the next 2-3 weeks of events that included meeting committers at Lucene/Solr Revolution and improving the existing SolrJ JDBC driver to work with DbVisualizer. By November, I had a POC that showed the Solr JDBC driver could be improved to support DbVisualizer, but I didn’t have the time to contribute it back yet.

In January of 2016, I contacted [Joel Bernstein](https://www.linkedin.com/in/bernsteinjoel) who had developed Parallel SQL ([SOLR-7560](https://issues.apache.org/jira/browse/SOLR-7560)) and the initial JDBC driver ([SOLR-7986](https://issues.apache.org/jira/browse/SOLR-7986)) to coordinate improving the JDBC driver. I created [SOLR-8502](https://issues.apache.org/jira/browse/SOLR-8502) to track this progress. I spent the next month breaking apart the existing POC into manageable pieces and putting those pieces up for review. Joel reviewed all of the JIRA subtasks and committed them. Almost every new nightly build provided proof that I was on the right track towards improving the Solr JDBC driver. [SOLR-8502](https://issues.apache.org/jira/browse/SOLR-8502) was completed in early February, which made DbVisualizer and some other JDBC clients work. I then created [SOLR-8659](https://issues.apache.org/jira/browse/SOLR-8659) to continue testing and improving the SolrJ JDBC driver for more SQL clients.

I was pleasantly surprised on Sunday March 13, 2016 when I got an email from Joel inviting me to become an Apache Lucene/Solr committer. In a few short days, it was official that I was an Apache Lucene/Solr committer and it was [announced](http://mail-archives.apache.org/mod_mbox/lucene-dev/201603.mbox/%3CCAE4tqLPcNwyJpsD8UBUJ67-52TVWDq-GY7H1Bk8_C1RO_7KFgA@mail.gmail.com%3E) on the community mailing list.

### What is next?
I’ll be cross posting the original LinkedIn articles on the Solr JDBC driver and step by step guides on how to configure a few SQL clients and database visualization tools to connect to Solr over the JDBC driver. If you have any questions about the Solr JDBC driver or want to help contribute, the Solr website has a section on [Community](https://lucene.apache.org/solr/resources.html#community) and how to use the solr-user mailing list.

