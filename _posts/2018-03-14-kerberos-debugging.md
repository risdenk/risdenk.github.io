---
title: Kerberos Debugging
date: 2018-03-14 12:00:00 -06:00
tags:
- bigdata
- kerberos
- debugging
- security
- logging
- apache
- hadoop
layout: post
---

### Overview
From 2013-2017, I worked for [Avalon Consulting, LLC](https://www.avalonconsult.com) as a [Hadoop](https://hadoop.apache.org) consultant. During this time I worked with a lot of clients and secured ([TLS/SSL](https://en.wikipedia.org/wiki/Transport_Layer_Security), [LDAP](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol), [Kerberos](https://web.mit.edu/kerberos/), etc) quite a few Hadoop clusters for both [Hortonworks](https://hortonworks.com/) and [Cloudera](https://www.cloudera.com/). There have been a few posts out there about debugging Kerberos problems like @steveloughran ["Hadoop and Kerberos: The Madness beyond the Gate"](https://steveloughran.gitbooks.io/kerberos_and_hadoop/content/). This post covers a few of the tips I've collected over the years that apply to Kerberos in general as well as to Apache Hadoop.

### Increase `kinit` verbosity
By default, `kinit` doesn't display any debug information and will typically come back with an obscure error on failure. The following command will enable verbose logging to standard out which can help with debugging.

```bash
KRB5_TRACE=/dev/stdout kinit -V
```

### Java Kerberos/KRB5 and SPNEGO Debug System Properties
Java internal classes that deal with Kerberos have system properties that turn on debug logging. The properties enable a **lot** of debugging so should only be turned on when trying to diagnose a problem and then turned off. They can also be combined if necessary.

The first property handles [Kerberos](https://web.mit.edu/kerberos/) errors and can help with misconfigured KDC servers, `krb5.conf` issues, and other problems.
```java
-Dsun.security.krb5.debug=true
```

The second property is specifically for [SPNEGO](https://en.wikipedia.org/wiki/SPNEGO) debugging for a Kerberos secured web endpoint. SPNEGO can be hard to debug, but this flag can help enable additional debug logging.
```java
-Dsun.security.spnego.debug=true
```

These properties can be set with `*_OPTS` variables for [Apache Hadoop](https://hadoop.apache.org/) and related components like the example below:
```bash
HADOOP_OPTS="-Dsun.security.krb5.debug=true" #-Dsun.security.spnego.debug=true"
```

### Hadoop Command Line Debug Logging
Most of the [Apache Hadoop](https://hadoop.apache.org/) command line tools (ie: `hdfs`, `hadoop`, `yarn`, etc) use the same underlying mechanism for logging `Log4j`. `Log4j` doesn't allow dynamically adjusting log levels, but it does allow the logger to be adjusted before using the commands. Hadoop exposes the root logger as an environment variable `HADOOP_ROOT_LOGGER`. This can be used to change the logging of a specific command without changing `log4j.properties`.
```bash
HADOOP_ROOT_LOGGER=DEBUG,console hdfs ...
```

### Debugging Hadoop Users and Groups
Users with [Apache Hadoop](https://hadoop.apache.org/) are typically authenticated through [Kerberos](https://web.mit.edu/kerberos/) as explained [here](https://hadoop.apache.org/docs/stable/hadoop-auth/index.html). The username of the user once authenticated is then used to determine groups. Groups with [Apache Hadoop](https://hadoop.apache.org/) can be configured in a variety of ways with [Hadoop Groups Mappings](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/GroupsMapping.html). Debugging what Apache Hadoop thinks your user and groups are is critical for setting up security correctly.

The first command takes a user principal and will return what the username is based on the configured [`hadoop.security.auth_to_local` rules](https://community.hortonworks.com/articles/14463/auth-to-local-rules-syntax.html).
```bash
hadoop org.apache.hadoop.security.HadoopKerberosName USER_PRINCIPAL
```

The second command takes the username and determines what the groups are associated with it. This uses the configured Hadoop Groups Mappings to determine what the groups are.
```bash
hdfs groups USERNAME
```

The third command is uses the currently authenticated user and prints out the current users UGI. It also can take a principal and keytab to print information about that UGI.
```bash
hadoop org.apache.hadoop.security.UserGroupInformation
hadoop org.apache.hadoop.security.UserGroupInformation "PRINCIPAL" "KEYTAB"
```

The fourth command [`KDiag`](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SecureMode.html#Troubleshooting_with_KDiag) is relatively new since it was introduced with [HADOOP-12426](https://issues.apache.org/jira/browse/HADOOP-12426) and first released in [Apache Hadoop](https://hadoop.apache.org/) 2.8.0. This command wraps up some additional debugging tools in one and checks common Kerberos related misconfigurations.
```bash
# Might also set HADOOP_JAAS_DEBUG=true and set the log level 'org.apache.hadoop.security=DEBUG'
hadoop org.apache.hadoop.security.KDiag
```

### Conclusion
More than half the battle of dealing with Kerberos and distributed systems is knowing where to look and what logs to generate. With the right logs, it becomes possible to debug the problem and resolve it quickly.

