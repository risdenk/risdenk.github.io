---
title: "%2F with WebHBase, Apache Knox, and Traefik - Part 1"
date: 2017-12-21 18:00:00 Z
tags:
- bigdata
- "%2f"
- apache
- knox
- traefik
layout: post
---

### Background
[WebHBase](https://hbase.apache.org/book.html#_rest) is a server that allows interacting with Apache HBase over HTTP REST. [Apache Knox](https://knox.apache.org/) simplies security around [Apache Hadoop](https://hadoop.apache.org/) and [Apache HBase](https://hbase.apache.org/). [Traefik](https://traefik.io/) is an HTTP software load balancer that we utilize to balance traffic between multiple Apache Knox servers.

<p style="text-align:center"><img width="350" src="/images/posts/2017-12-21/traefik_knox_webhbase_diagram.svg" /></p>

### Problem
One of the groups I work with had stored data in HBase with forward slashes (`/`) in the [rowkey](https://hbase.apache.org/book.html#rowkey.design). This translates to [`%2F`](https://www.w3schools.com/tags/ref_urlencode.asp)  based on URL encoding. We started to call this problem the "`%2F` problem" because each layer from WebHBase back up to the client had issues with `%2F`.

### Apache HBase, WebHBase, and `%2F`
Apache HBase stores and retrieves data as byte arrays. This data can be encoded by the user in a variety of ways. WebHBase will take byte arrays and typically will Base64 encode them to ensure they are safe to transmit over HTTP. The user can then decode the Base64 encoded string to retrieve the results.

When working with WebHBase, the namespace, table, and rowkey are entered in the URL as per the [specification](http://hbase.apache.org/book.html#_rest). These parameters must be URL encoded to ensure there is no confusion between regular forward slashes in the URL and for data. WebHBase handles this correctly and doesn't convert `%2F` encoding to forward slashes when referencing namespaces, tables, or rowkeys.

**Note** - Even though it does work, I absolutely do not recommend using `%2F` as part of any data where URL encoding is involved. There is no guarantee what will happen.

### Apache Knox and `%2F`
Apache Knox handles authentication and in our case converts from basic authentication (username/password) to Kerberos before handing off to our Hadoop cluster. Other than handling authentication, Knox should not be modifying the request in any meaningful way other than pointing to a new backend. The request should be passed through without changing the URL encoding as well. 

#### Debugging Knox for `%2F`
During testing, we noticed that Knox was taking `%2F` URLs and converting them to `/` when dispatching to the backend. We were able to determine this because [Knox audit log format](https://cwiki.apache.org/confluence/display/EAG/Monitor+Apache+Knox+audit+log) keeps track of the original requested URL and the dispatched URL. After figuring out this was happening and the behavior had changed between Knox 0.6.x and 0.9.x, I [emailed the knox-user mailing list](http://mail-archives.apache.org/mod_mbox/knox-user/201705.mbox/%3CCAJU9nmixhALoSHkFfUpwybFBwXdo=Y4vnGMvnJwwOeuCETA_uQ@mail.gmail.com%3E) to see if this was to be expected. Here is an excerpt of the testing results:

**Works – Knox 0.6.x (HDP 2.3)**
```
17/05/23 16:54:13
||7c4131fc-8638-4a1a-9228-d9a67a312a40|audit|WEBHBASE|USER|||dispatch|uri|
http://HOST:8084/ns:table/%2frkpart1%2frkpart2?doAs=USER|success|Response
status: 200
```

**Doesn’t work – Knox 0.9.x (HDP 2.5)**
```
17/05/23 17:23:13
||4244f242-6694-40bb-914d-8dc7e222f074|audit|WEBHBASE|USER|||dispatch|uri|
http://HOST:8084/ns%3Atable/rkpart1/rkpart2?doAs=USER|success|Response
status: 404
```

It was determined that this behavior was not intended and so I went about trying to figure out what caused this to occur.

I pulled down a few Knox versions 0.8.0 and 0.9.0 and found that it did not affect 0.8.0. I pulled down the code from the [Hortonworks knox-release source](https://github.com/hortonworks/knox-release/tree/HDP-2.5.3.77-tag) at tag `HDP-2.5.3.77-tag` and did a `git bisect` to find the offending commit using this [test case](https://gist.github.com/risdenk/afecc66d6fc0c9d665abd1ae5466f341). The offending commit is [c28224c](https://git-wip-us.apache.org/repos/asf?p=knox.git;h=c28224c) and related JIRA is [KNOX-690](https://issues.apache.org/jira/browse/KNOX-690).

#### Fixing Knox URL encoding
I rebuilt Knox from the [Hortonworks knox-release source](https://github.com/hortonworks/knox-release/tree/HDP-2.5.3.77-tag) at tag `HDP-2.5.3.77-tag` with the commit `c28224c` reverted. The adjusted code is [here](https://github.com/risdenk/knox-release/tree/hdp25_revert_KNOX-690). The change is only a single commit [dc45212](https://github.com/risdenk/knox-release/commit/dc452126de99f6f1d15938f7294e95e3b7c89328).

I rebuilt Knox with `mvn -DskipTests package` and copied the two affected jars (`gateway-provider-rewrite` and `gateway-util-urltemplate`) to `/usr/hdp/current/knox-server/lib/`. After restarting Knox, this made `%2F` encoded row keys work correctly. 

Based on the work above, [KNOX-949](https://issues.apache.org/jira/browse/KNOX-949) and [KNOX-1005](https://issues.apache.org/jira/browse/KNOX-1005) fixed the URL encoding issues in Apache Knox. The issue was more widespread than just `%2F` but `%2F` is an interesting case just by itself. [Apache Knox 0.14.0](https://cwiki.apache.org/confluence/display/KNOX/Release+0.14.0) is the first release with the URL encoding issues fixed after Knox 0.6.0.

### To be continued in part 2...
[Part 2]({% post_url 2017-12-22-percent-2f-webhbase-knox-traefik-part-2 %}) of this blog post covers how the "`%2F` problem" manifested itself in Traefik after we were able to fix Apache Knox.

