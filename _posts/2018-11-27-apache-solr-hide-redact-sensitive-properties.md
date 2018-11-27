---
title: Apache Solr - Hide/Redact Senstive Properties
date: 2018-11-27 08:00:00 -06:00
tags:
- bigdata
- apache
- solr
- security
- hide
- redact
- sensitive
layout: post
---

### Overview
[Apache Solr](https://lucene.apache.org/solr) is a full text search engine that is built on [Apache Lucene](https://lucene.apache.org/solr/). One of the common questions on the [solr-user](http://lucene.apache.org/solr/community.html#mailing-lists-irc) mailing list (ie: [here](http://lucene.472066.n3.nabble.com/Disabling-jvm-properties-from-ui-td4413066.html) and [here](http://lucene.472066.n3.nabble.com/jira-Commented-SOLR-11369-Zookeeper-credentials-are-showed-up-on-the-Solr-Admin-GUI-td4405383.html)) is how to hide sensitive values from the [Solr UI](https://lucene.apache.org/solr/guide/7_5/overview-of-the-solr-admin-ui.html). There is a little known setting that enables hiding these sensitive values. 

### Apache Solr and Hiding Sensitive Properties
Apache Solr has a few places where sensitive values can be seen on the Solr UI. The keystore and truststore passwords are two examples that came up as part of [SOLR-10076](https://issues.apache.org/jira/browse/SOLR-10076). Starting in Solr 6.6 and 7.0, Solr will hide any property in the `/admin/info/system` API that contains the word `password` when the system property `solr.redaction.system.enabled` is set to true. The `/admin/info/system` API is used to power the Solr UI. This works well for most cases, but the implementation is more generic enabling it to hide any custom properties.

The property `solr.redaction.system.pattern` is a system property that takes a regular expression. If the regular expression matches the property name then the system property value will be redacted. This can enable hiding sensitive values for custom libraries or other use cases.

The table below lays out the two properties that can be configured in Solr 6.6 or later.

| Property | Default Value | Purpose |
|----------|---------------|---------|
| `solr.redaction.system.enabled` | `false` in Solr 6.6; `true` in Solr 7.0 | Enables or disables the redaction | 
| `solr.redaction.system.pattern` | `.*password.*` | Regex for the properties to redact |

### Apache Solr and Hiding Metrics Properties
The [Solr Metrics API](https://lucene.apache.org/solr/guide/7_5/metrics-reporting.html) can leak sensitive information as well. There is a [`hiddenSysProps` configuration](https://lucene.apache.org/solr/guide/7_5/metrics-reporting.html#the-metrics-hiddensysprops-element) that can prevent certain properties from being exposed via the metrics API. If additional properties need to be hidden then they need to be configured in the `hiddenSysPropes` section.

### Conclusion
Currently, there is limited documentation about the available options for hiding sensitive values. It is frustrating to have to configure hiding sensitive values in two places, but there is hope for improvement. [SOLR-12976](https://issues.apache.org/jira/browse/SOLR-12976) was created earlier this month to try to address the duplication and documentation.

