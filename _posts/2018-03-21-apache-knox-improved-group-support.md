---
title: Apache Knox - Improved Group Support
date: 2018-03-21 09:00:00 -05:00
tags:
- bigdata
- apache
- knox
- group
- ranger
- security
layout: post
---

### Overview
[Apache Knox](https://knox.apache.org/) is a reverse proxy that simplifies security in front of a Kerberos secured [Apache Hadoop](https://hadoop.apache.org/) cluster and other related components. Group support is critical for Knox since it enables authorization for different topologies without specifying individual users. Historically, Knox group support was limited resulting in minimal authorization at the topology level. [Apache Ranger](https://ranger.apache.org/) integration with Knox makes it easy to administer authorization policies. With improved group support in Apache Knox, authorization policies, like the ones created with Ranger, can use groups effectively. [Knox Improvement Proposal 1 (KIP-1)](https://cwiki.apache.org/confluence/display/KNOX/KIP-1+LDAP+Improvements) was created in November 2016 to focus on group improvements.

### Apache Knox \<0.10.0 Group Limitations
Apache Knox added group support from the very beginning relying on [Apache Shiro](https://shiro.apache.org/). As the Hadoop ecosystem grew there was a lot of overlap in group implementations. Each had to correctly implement paging, nested OUs, PAM support, and using computed attributes like memberOf. After the creation of [KIP-1](https://cwiki.apache.org/confluence/display/KNOX/KIP-1+LDAP+Improvements), the Knox community worked on improving group support. Apache Knox 0.10.0 was the first version to get significant group improvements.

### Apache Knox 0.10.0 Group Improvements
Prior to Apache Knox 0.10.0, group support was limited to implementations that had <1000 groups. For large companies that rely on groups, 1000 groups is a small number. [KNOX-644](https://issues.apache.org/jira/browse/KNOX-644) focused on removing this limitation by paging the results. After hitting this a few times at various security implementations, I put together a patch to handle >1000 groups. This improved group support but there are still some limitations like performance which could be improved with [KNOX-461](https://issues.apache.org/jira/browse/KNOX-461). However there was another improvement in Knox 0.10.0 to attack the group problem differently.

Linux PAM support was added to Knox 0.10.0 with [KNOX-537](https://issues.apache.org/jira/browse/KNOX-537). This allows Knox to leverage existing group tools like [SSSD](https://en.wikipedia.org/wiki/System_Security_Services_Daemon) to handle complex scenarios. This can include caching and leveraging existing OS configurations. This also supports nested OUs which is a limitation of the existing LDAP group implementation.

The [Apache Knox Blog](https://cwiki.apache.org/confluence/pages/viewrecentblogposts.action?key=KNOX) also detailed the improvements in Knox 0.10.0 as well [here](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=66854729).

### Apache Knox 0.11.0 Group Improvements
Apache Knox 0.11.0 continued to improve on the group support added in 0.10.0. The main improvement was adding support for the `HadoopGroupProvider` as an identity provider in [KNOX-237](https://issues.apache.org/jira/browse/KNOX-237). With this addition, Knox is able to leverage the work done by the [Apache Hadoop](https://hadoop.apache.org/) community on group support. The Hadoop group module has been significantly tested since it forms the basis of group lookup for many Hadoop components. The [Apache Knox Blog](https://cwiki.apache.org/confluence/pages/viewrecentblogposts.action?key=KNOX) has more details on this [here](https://cwiki.apache.org/confluence/display/KNOX/2017/06/22/Hadoop+Group+Lookup+Provider).

### Apache Knox 1.0.0 & Current Status
In February 2018, Apache Knox 1.0.0 was released signifying a major milestone for the Knox project. Since Knox 0.11.0 improving group support hasn't been a big focus since the identified problems have been resolved. It is possible today to configure Apache Knox with most group backends without any issues.

