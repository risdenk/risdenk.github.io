---
title: Elasticsearch Java High Level REST Client - Scroll API - Load Balancer
date: 2017-12-24 12:00:00 -06:00
tags:
- bigdata
- elasticsearch
- scroll
- load
- balancer
- java
- client
- rest
- high
- level
layout: post
---

### Overview
We used a software load balancer to handle traffic between many of our different services. This allows us to completely isolate our backend changes from our [REST](https://en.wikipedia.org/wiki/Representational_state_transfer) clients. The same load balancer infrastructure handles [Elasticsearch](https://www.elastic.co/products/elasticsearch) and [Apache Hadoop](https://hadoop.apache.org). This allows REST clients to interact with both without having multiple connection points.

An example of the load balancing infrastructure is as follows:

<p style="text-align:center"><img width="500" src="/images/posts/2017-12-24/load_balancer_elasticsearch.svg" /></p>

The load balancer connects to Elasticsearch client or data nodes depending on the size of the cluster. This prevents a single point of failure when connecting to our Elasticsearch infrastrucure.

### Elasticsearch and the new Java High Level REST Client
One of our REST clients uses the new [Java High Level REST Client]() to connect via our load balancing infrastructure. The Java client works much better than the [low level client](https://www.elastic.co/guide/en/elasticsearch/client/java-rest/master/java-rest-low.html) for simple operations. Furthermore, we have reduced the number of firewall ports that need to be exposed to users compared to the older [transport client](https://www.elastic.co/guide/en/elasticsearch/client/java-api/5.6/transport-client.html). There have been very few issues moving from the transport client to the Java High Level REST Client. The [Java High Level REST client documentaton and supported APIs](https://www.elastic.co/guide/en/elasticsearch/client/java-rest/master/java-rest-high.html) keep improving with each release.

### Elasticsearch Java High Level REST Client Scroll API and Load Balancing
The [Elasticsearch Scroll API](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/search-request-scroll.html) allows a client to retrieve a large number of results if necessary. The Scroll API can make multiple requests for each partition of the results until there are no more. The multiple requests mean that the Java High Level REST Client must be configured correctly or only the first request will work.

For our load balancer infrastructure, we rely on URL path prefixes to handle all requests behind the same domain. This makes it easier to not request a new domain for each new load balancer endpoint. The URL path prefix must be configured in the Java High Level REST Client initialization otherwise the requests will fail.

The [Java High Level REST Client initialization](https://www.elastic.co/guide/en/elasticsearch/client/java-rest/master/java-rest-high-getting-started-initialization.html) states that you must first build a [Java Low Level REST Client](https://www.elastic.co/guide/en/elasticsearch/client/java-rest/master/java-rest-low-usage-initialization.html). The [Java Low Level REST Client documentation](https://www.elastic.co/guide/en/elasticsearch/client/java-rest/master/java-rest-low.html) does not state how to pass the load balancer path prefix and so Scroll API requests fail.

The trick is to configure the Java Low Level REST Client with the Elastic [`RestClientBuilder` class](https://artifacts.elastic.co/javadoc/org/elasticsearch/client/elasticsearch-rest-client/5.6.5/org/elasticsearch/client/RestClientBuilder.html). This class takes care of building the actual `RestClient`. The method [`setPathPrefix`](https://artifacts.elastic.co/javadoc/org/elasticsearch/client/elasticsearch-rest-client/5.6.5/org/elasticsearch/client/RestClientBuilder.html#setPathPrefix-java.lang.String-) allows setting the prefix that the load balancer requires. With this in place, the Scroll API requests now work correctly.

### Conclusion
Using the Elastic Java High Level REST Client sometimes requires understanding how the Java Low Level REST Client works. The Elastic Java REST client Javadoc ([low level](https://www.elastic.co/guide/en/elasticsearch/client/java-rest/5.6/java-rest-low-javadoc.html) and [high level](https://www.elastic.co/guide/en/elasticsearch/client/java-rest/5.6/java-rest-high-javadoc.html)) can be very helpful in determining what features are available where official documentation examples are lacking.

