---
title: Apache Solr - Hadoop Authentication Plugin - LDAP
date: 2018-11-20 08:00:00 -06:00
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
[Apache Solr](https://lucene.apache.org/solr) is a full text search engine that is built on [Apache Lucene](https://lucene.apache.org/solr/). One of the questions I've been asked about in the past is LDAP support for Apache Solr authentication. While there are commercial additions that add LDAP support like [Lucidworks Fusion](https://lucidworks.com/products/fusion-server/), Apache Solr doesn't have an LDAP authentication plugin out of the box. Lets explore what the current state of authentication is with Apache Solr.

### Apache Solr and Authentication
Apache Solr 5.2 released with a pluggable authentication module from [SOLR-7274](https://issues.apache.org/jira/browse/SOLR-7274). This paved the way for future authentication implementations such as `BasicAuth` ([SOLR-7692](https://issues.apache.org/jira/browse/SOLR-7692)) and Kerberos ([SOLR-7468](https://issues.apache.org/jira/browse/SOLR-7468)). In Apache Solr 6.1, delegation token support ([SOLR-9200](https://issues.apache.org/jira/browse/SOLR-9200)) was added to the Kerberos authentication plugin. Apache Solr 6.4 added a significant feature for hooking the [Hadoop authentication framework](https://hadoop.apache.org/docs/current/hadoop-auth/Configuration.html) directly into Solr as an authentication plugin ([SOLR-9513](https://issues.apache.org/jira/browse/SOLR-9513)). There haven't been much more work on authentication plugins lately. Some work is being done to add a JWT authentication plugin currently ([SOLR-12121](https://issues.apache.org/jira/browse/SOLR-12121)). Each Solr authentication plugin provides additional capabilities for authenticating to Solr.

### Hadoop Authentication, LDAP, and Apache Solr
#### Hadoop Authentication Framework Overview
The [Hadoop authentication framework](https://hadoop.apache.org/docs/current/hadoop-auth/Configuration.html) provides additional capabilities since it has added backends. The backends currently include Kerberos, AltKerberos, LDAP, SignerSecretProvider, and Multi-scheme. Each can be configured to support varying needs for authentication. 

#### Apache Solr and Hadoop Authentication Framework
Apache Solr 6.4+ supports the Hadoop authentication framework due to the work of [SOLR-9513](https://issues.apache.org/jira/browse/SOLR-9513). The [Apache Solr reference guide](https://lucene.apache.org/solr/guide/7_5/hadoop-authentication-plugin.html) provides guidance on how to use the Hadoop Authentication Plugin. All the necessary configuration parameters can be passed down to the Hadoop authentication framework. As more backends are added to the Hadoop authentication framework, Apache Solr just needs to upgrade the Hadoop depdendency to gain support.

#### Apache Solr 7.5 and LDAP
LDAP support for the Hadoop authentication framework was added in Hadoop 2.8.0 ([HADOOP-12082](https://issues.apache.org/jira/browse/HADOOP-12082)). Sadly, the Hadoop dependency for Apache Solr 7.5 is only on [2.7.4](https://github.com/apache/lucene-solr/blob/branch_7_5/lucene/ivy-versions.properties#L156). This means that when you try to configure the HadoopAuthenticationPlugin` with LDAP, you will get the following error:

```
Error initializing org.apache.solr.security.HadoopAuthPlugin: 
javax.servlet.ServletException: java.lang.ClassNotFoundException: ldap
```

#### Manually Upgrading the Apache Solr Hadoop Dependency
**Note:** I don't recommend doing this outside of experimenting and seeing what is possible.

I put together a [simple test project](https://github.com/risdenk/test-solr-hadoopauthenticationplugin-ldap) that "manually" replaces the Hadoop 2.7.4 jars with 2.9.1 jars. This was designed to test if it is possible to configure the Solr `HadoopAuthenticationPlugin` with LDAP. I was able to configure Solr using the following `security.json` file to use the Hadoop 2.9.1 LDAP backend.

```json
{
    "authentication": {
        "class": "solr.HadoopAuthPlugin",
        "sysPropPrefix": "solr.",
        "type": "ldap",
        "authConfigs": [
            "ldap.providerurl",
            "ldap.basedn",
            "ldap.enablestarttls"
        ],
        "defaultConfigs": {
            "ldap.providerurl": "ldap://ldap",
            "ldap.basedn": "dc=example,dc=org",
            "ldap.enablestarttls": "false"
        }
    }
}
```

With this configuration and the Hadoop 2.9.1 jars, Apache Solr was protected by LDAP. There should be more testing done to see how this plays with multiple nodes and other types of integration required. The Hadoop authentication framework has limited support for LDAP but it should be usable for some usecases.

### Conclusion
Apache Solr, as of 7.5, is currently limited as to what support it has for the Hadoop authentication framework. This is due to the depenency on Apache Hadoop 2.7.4. When the Hadoop dependency is updated ([SOLR-9515](https://issues.apache.org/jira/browse/SOLR-9515)) in Apache Solr, there will be at least some initial support for LDAP integration out of the box with Solr.

#### References
* [https://lucene.apache.org/solr/guide/7_5/securing-solr.html](https://lucene.apache.org/solr/guide/7_5/securing-solr.html)
* [https://lucene.apache.org/solr/guide/7_5/hadoop-authentication-plugin.html](https://lucene.apache.org/solr/guide/7_5/hadoop-authentication-plugin.html)
* [https://issues.apache.org/jira/browse/SOLR-9513](https://issues.apache.org/jira/browse/SOLR-9513)
* [https://stackoverflow.com/questions/50647431/ldap-integration-with-solr](https://stackoverflow.com/questions/50647431/ldap-integration-with-solr)
* [https://community.hortonworks.com/questions/130989/solr-ldap-integration.html](https://community.hortonworks.com/questions/130989/solr-ldap-integration.html)
* [https://github.com/apache/lucene-solr/blob/branch_7_5/lucene/ivy-versions.properties#L156](https://github.com/apache/lucene-solr/blob/branch_7_5/lucene/ivy-versions.properties#L156)
* [https://issues.apache.org/jira/browse/HADOOP-12082](https://issues.apache.org/jira/browse/HADOOP-12082)

