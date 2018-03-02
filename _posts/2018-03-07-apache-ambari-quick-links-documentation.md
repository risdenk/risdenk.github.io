---
title: Apache Ambari - Quick Links Documentation
date: 2018-03-07 12:00:00 -06:00
tags:
- bigdata
- apache
- ambari
- quick links
- documentation
layout: post
---

### Overview
[Apache Ambari](https://ambari.apache.org/) makes managing distributed systems like [Apache Hadoop](https://hadoop.apache.org/) easier. One of the capabilities of Ambari is [Quick Links](https://cwiki.apache.org/confluence/display/AMBARI/Quick+Links) which allows for easily linking to service UIs. 

### Case Sensitivity for `quicklinks.json`
As of late February 2018, the [Quick Links documentation](https://cwiki.apache.org/confluence/display/AMBARI/Quick+Links) invalidly states that `http_only` and `https_only` will work. When trying to use the lowercase version of `http_only` and `https_only` Ambari ignored this config and the quick links did not work as designed. Instead you must use upper case `HTTP_ONLY` or `HTTPS_ONLY` in `quicklinks.json`. 

### What is next?
I created [AMBARI-21300](https://issues.apache.org/jira/browse/AMBARI-21300) to try to fix the documentation page. I don't have the ability to edit the Apache Ambari confluence documentation. It would be great to update the documentation to avoid future frustration.

