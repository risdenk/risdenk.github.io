---
title: Elasticsearch - X-Pack - _has_privileges NPE
date: 2018-02-28 12:00:00 -06:00
tags:
- bigdata
- elastic
- elasticsearch
- x-pack
- has_privileges
- security
layout: post
---

### Overview
[Elasticsearch](https://www.elastic.co/products/elasticsearch) security is implemented through [X-Pack](https://www.elastic.co/guide/en/x-pack/current/xpack-introduction.html) which is an [Elastic](https://www.elastic.co/) proprietary component. Although [Elasticsearch is released under an open source license](https://github.com/elastic/elasticsearch), X-Pack is developed solely by Elastic without external influence. This is [changing soon](https://www.elastic.co/blog/doubling-down-on-open) in Elastic Stack 6.3 with Elastic [making the X-Pack code available](https://www.elastic.co/products/x-pack/open).

### NPE with X-Pack `_has_privileges` API
While exploring capabilities provided by X-Pack, I found the [`_has_privileges` Privilege API](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-api-privileges.html) that "allows you to determine whether the logged in user has a specified list of privileges.". I expected that issuing a call to `_has_privileges` would return what the user was allowed to do. I made the request as documented [here](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-api-privileges.html#_request_41).

[http://localhost:9200/_xpack/security/user/_has_privileges](http://localhost:9200/_xpack/security/user/_has_privileges)
```json
{"error":{"root_cause":[{"type":"null_pointer_exception","reason":null}],"type":"null_pointer_exception","reason":null},"status":500}
```

The resulting `NullPointerException` (NPE) demonstrates that there is an issue with handling the request. Without access to the source code (X-Pack is closed source) it was impossible to debug this further.

I opened a support case with Elastic and have informed Elastic representatives this bug existed. This bug has existed since late 2017. I found it in Elasticsearch 5.5.x and Elasticsearch 6.0 beta. [Elasticsearch 5.6.x](https://www.elastic.co/guide/en/x-pack/5.6/xpack-change-list.html) still has this bug. I informed Elastic that Elasticsearch 6.0 beta had this issue as well. Elasticsearch >=6.1.0 has finally fixed this issue but it was not backported to Elasticsearch 5.6.x or 6.0.x as of late Feburary 2018.

### Reproducing this with Elasticsearch 5.6.8
This was tested on Mac OS X but should also work on Linux.

#### Terminal Window 1
```bash
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.6.8.tar.gz
tar zxvf elasticsearch-5.6.8.tar.gz
cd elasticsearch-5.6.8/
./bin/elasticsearch-plugin install x-pack -b
./bin/elasticsearch
```

#### Terminal Window 2
```bash
curl http://localhost:9200/_xpack/security/user/_has_privileges
{"error":{"root_cause":[{"type":"null_pointer_exception","reason":null}],"type":"null_pointer_exception","reason":null},"status":500}
```

### NPE Fixed in Elasticsearch X-Pack >=6.1.0
This was first fixed in [Elasticsearch X-Pack 6.1.0](https://www.elastic.co/guide/en/elasticsearch/reference/current/xes-6.1.0.html#xes-bug-6.1.0).

> Fixed REST requests that required a body but did not validate it, resulting in null pointer exceptions.

### X-Pack Code Available by EULA
With X-Pack code becoming available in Elastic Stack 6.3, it will be possible to now debug and help pinpoint NPE exceptions. There is no guarantee that Elastic will fix these issues but collaboration is easier. Although not explicitly open source by the OSI definition, it will be possible to see the code.

