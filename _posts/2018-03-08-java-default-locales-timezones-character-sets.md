---
title: Java - Default Locales, Timezones, and Character Sets
date: 2018-03-08 12:00:00 -06:00
tags:
- java
- locale
- timezone
- character set
- forbidden
- forbidden-apis
- apache
- calcite
layout: post
---

### Overview
[Java](https://java.com/) is a prolific programming language that is used in everything from phones to cars to desktops to servers. Software that is used around the world must work in different locales, timezones, and character sets. By default, Java doesn't protect programmers from making poor decisions when it comes to international software. [Apache Lucene/Solr](https://lucene.apache.org/), which I am a commiter to, led the way in dealing with preventing bad habits with automated tools.

### Dealing with Turkish locale
One example of Java's bad default behavior is with lowercasing strings. With the Turkish locale, lowercasing or uppercasing a string can result in multiple formats. `Locale.getDefault()` causes issues with the Turkish locale. The default method `java.lang.String@toLowerCase()` is dangerous in this regard. Instead you should use `Locale.ROOT` to avoid locale specific case changing. If you are not presenting the string, it won't matter if you use `Locale.ROOT`.

### Introduction to `forbidden-apis`
[`forbidden-apis`](https://github.com/policeman-tools/forbidden-apis) is a project written by @uschindler that hooks into the build process to prevent certain API usage. The build can be configured to fail if a signature is found. `forbidden-apis` can be used with [Apache Ant](https://ant.apache.org/), [Apache Maven](https://maven.apache.org/), and [Gradle](https://gradle.org/). The automated tool `forbidden-apis` makes it impossible to use methods that have ambiguous locale, timezone, and charset implications. The `forbidden-apis` tool is used in Apache Lucene/Solr to prevent these types of problems from occuring. `forbidden-apis` has been blogged about [here](http://blog.thetaphi.de/2012/07/default-locales-default-charsets-and.html), [here](http://blog.joda.org/2012/12/annotating-jdk-default-data.html), and [here](http://furkankamaci.com/forbidden-apis-of-java/).

### Apache Caclite and `forbidden-apis`
[Apache Calcite](https://calcite.apache.org/) is a project that provides pieces to build a database including SQL parsing and query optimization. I [integrated Apache Calcite into Apache Solr](https://issues.apache.org/jira/browse/SOLR-8593) to improve the SQL support. During this integration, Apache Solr automated tests found an [issue](https://issues.apache.org/jira/browse/SOLR-10353) with Apache Calcite and its handling of locales, timezones, and charsets. [CALCITE-1667](https://issues.apache.org/jira/browse/CALCITE-1667) tracked integrating `forbidden-apis` to ensure that problems don't creep back into later releases. In the first half of 2017, Apache Calcite 1.12.0 and Apache Calcite Avatica 1.10.0 were released fixing the issues mentioned above.

### What is next?
`forbidden-apis` can prevent issues that are not easy to predict with automated tests. Not many developers test across multiple locales, timezones, and charsets. `forbidden-apis` is one more tool to help make stable software.

