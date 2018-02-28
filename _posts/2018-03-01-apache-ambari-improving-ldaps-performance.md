---
title: Apache Ambari - Improving LDAPS Performance
date: 2018-03-01 12:00:00 -06:00
tags:
- bigdata
- apache
- ambari
- ldaps
- performance
layout: post
---

### Overview
[Apache Ambari](https://ambari.apache.org/) makes managing distributed systems like [Apache Hadoop](https://hadoop.apache.org/) easier. One of the capabilities of Ambari is integrating with LDAP when authenticating users. Currently we sync multiple LDAP groups with Ambari and started to notice `Connection reset` errors in the logs when running an Ambari LDAP sync.

### Determine root cause of `Connection reset`
During October 2017, @quirogadf noticed the original `Connection reset` errors and worked to determine the root cause. He noticed that these errors only occurred when using LDAPS and did not happen when LDAP was being used. Over the past few months, we had increased the number of groups to sync to Ambari and were using LDAPS exclusively. Switching back to LDAP without TLS/SSL was not an option. Also decreasing the number of groups didn't seem reasonable either since this worked with regular LDAP.

After some time pondering the root cause, David found two references which helped narrow down the issue:
* [https://confluence.atlassian.com/jirakb/connecting-jira-to-active-directory-over-ldaps-fails-with-connection-reset-763004137.html](https://confluence.atlassian.com/jirakb/connecting-jira-to-active-directory-over-ldaps-fails-with-connection-reset-763004137.html)
* [https://docs.oracle.com/javase/jndi/tutorial/ldap/connect/config.html](https://docs.oracle.com/javase/jndi/tutorial/ldap/connect/config.html)

The root cause ended up being that LDAPS connections are not pooled by default where LDAP connections are pooled. Without pooling LDAPS connections, there were significantly more open connections in Active Directory in our case resulting in `Connection reset`.

### Improving Apache Ambari LDAPS Performance
Once @quirogadf had determined the root cause, we worked to make the suggested change to Apache Ambari. `/var/lib/ambari-server/ambari-env.sh` contains all the environment setup for Ambari Server. We were able to add the following line to `ambari-env.sh`:

```
# ldap connection pooling
export AMBARI_JVM_ARGS=$AMBARI_JVM_ARGS" -Dcom.sun.jndi.ldap.connect.pool.protocol='plain ssl' -Dcom.sun.jndi.ldap.connect.pool.maxsize=20 -Dcom.sun.jndi.ldap.connect.pool.timeout=300000"
```

This simple change removed all the `Connection reset` errors that we were seeing with LDAPS.

### What is next?
In December 2017, @quirogadf created [AMBARI-22642](https://issues.apache.org/jira/browse/AMBARI-22642) to inform the Apache Ambari community that this change would help with LDAPS. David also created a patch with the LDAPS additions to `ambari-env.sh`. We are waiting on the Ambari community to review and commit this patch. Until then we will continue adding LDAPS connection pooling to `ambari-env.sh`.

