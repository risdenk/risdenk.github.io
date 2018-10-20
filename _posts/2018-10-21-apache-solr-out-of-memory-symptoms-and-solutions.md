---
title: Apache Solr - Out of Memory (OOM) Symptoms and Solutions
date: 2018-10-21 09:00:00 -05:00
tags:
- bigdata
- apache
- solr
- stability
- oom
- out of memory
- symptoms
- solutions
- faceting
- sorting
- docValues
layout: post
---

### Overview
[Apache Solr](https://lucene.apache.org/solr) is a full text search engine that is built on [Apache Lucene](https://lucene.apache.org/solr/). I've been working with Apache Solr for the past six years. Over that time Apache Solr has released multiple major versions from 4.x, 5.x, 6.x, 7.x and soon 8.x. One of the common problems with Java based applications is out of memory. There have been a few posts on the topic and want to reiterate some of the symptoms and solutions. 

### Symptoms and Solutions
#### Large number of rows
Apache Solr is a scoring engine underneath the hood. This means that it is designed to return the best ranked documents for the end user. One of the common use cases is ecommerce where the top 5-10 results need to match what the user is looking for or they will go elsewhere. Solr can also be used in the analytics space where large result sets need to be returned if matching a set of search criteria. Returning a large number of rows is possible with Solr but this cannot be done with `rows=1000000`. 

The [`rows` parameter](https://lucene.apache.org/solr/guide/7_5/common-query-parameters.html#CommonQueryParameters-TherowsParameter) for Solr can be used to return more than the default of 10 rows. I have seen users successfully set the `rows` parameter to 100-200 and not see any issues. However, setting the `rows` parameter higher has a big memory consequence and should be avoided at all costs. The Solr wiki has details about the memory consumption when requesting a lot of rows [here](https://wiki.apache.org/solr/SolrPerformanceProblems#Asking_for_too_many_rows). Furthermore, a high `rows` parameter means that in each shard in a Solr Cloud setup will need to return that many rows to the leader for final sorting and processing. This can significantly slow down the query even if not running into any memory problems.

An out of memory (OOM) error typically occurs after a query comes in with a large `rows` parameter. Solr will typically work just fine up until that query comes in. Sometimes this can be hard to track down but looking at the Solr logs will help here. It may be tempting to increase heap to resolve this error but be aware that that will not solve the issue. Some ideas for solutions to this problem are below [here](#paging-through-large-number-of-results).

**Large start for paging results**

As with large number of rows above, Solr can be used to return a lot of rows. One of the patterns that I've seen is not using a large `rows` parameter but instead using a large [`start` parameter](https://lucene.apache.org/solr/guide/7_5/common-query-parameters.html#CommonQueryParameters-TherowsParameter) like `start=1000000`. By using the `rows` and `start` parameters, many users think they will be able to get millions of results back from Solr. This will work in a test environment but for actual millions of rows this pattern will fail. This will most likely not cause an OOM memory problem, but results will not be returned quickly. The same solutions can help in this situation as well. For more details see [here](#paging-through-large-number-of-results).

#### Faceting/sorting/grouping OOM
Apache Solr has a fantastic feature called faceting that allows for counts of terms in the index. This can be used in a variety of different ways. Sorting is also core to Solr in that we want to be able to return relevant results based on a user's sort criteria. The problem with faceting and sorting is that they are done on the uninverted values stored in the index. What that means to users who are not familiar with Lucene, is that the original tokens need to be available and not just the location in the document.

When it comes to memory usage, if a field in Solr needs to be faceted or sorted and the uninverted representation is not available it will be built on heap. This result is then cached in the [FieldCache](http://lucene.apache.org/solr/7_5_0/solr-core/org/apache/solr/uninverting/FieldCache.html). Every time the index is changed the field needs to be uninverted again and stored on heap. This can take up a lot of heap and caused out of memory (OOM). This may not happen immediately but over time the more uninverted fields are put on the FieldCache.

This symptom comes up often during analytics when someone wants to explore an index with a tool like [Banana](https://github.com/lucidworks/banana). Banana is built on faceting and sorted so it requires that most fields in the index be uninverted. This can cause a previously working Solr setup to crash due to OOM errors.

There is good news since starting from Apache Lucene/Solr 4.0, there is a new feature called [DocValues](https://lucene.apache.org/solr/guide/7_5/docvalues.html). There is more information in the solutions section [here](#facetingsortinggrouping-on-large-indices).

### Solutions
#### Paging through large number of results
Instead of using the `rows` or `start` parameters to request more rows, it is more appropriate to use the [`/export` handler](https://lucene.apache.org/solr/guide/7_5/exporting-result-sets.html#ExportingResultSets-The_exportRequestHandler) or [`cursorMark`](https://lucene.apache.org/solr/guide/7_5/pagination-of-results.html). The `/export` handler ensures that results are streamed back in a way that scales to millions of rows. `cursorMark` allows for a high number of pages to be returned without incurring the sort cost repeatedly that occurs with a large `start` parameter. This also ensures that a large number of rows are not returned at once. By using the `/export` handler and `cursorMark` you will be able to retreive large result sets without causing any out of memory errors.

#### Faceting/sorting/grouping on large indices
Apache Lucene/Solr 4.0 introduced a new feature called [DocValues](https://lucene.apache.org/solr/guide/7_5/docvalues.html). DocValues store the values necessary for faceting/sorting/grouping at index time and avoid the need to store them on heap. This significantly reduces the amount of heap necessary for running Solr. There is very little tradeoff to enabling DocValues for all fields that you may need to factet/sort/group on. Solr 6.x enabled DocValues by default for most fields. If you are on Solr 5.x you should be able to enable DocValues since the capability is there.

### Debugging
If none of the solutions above work, then it is useful to know how to debug related problems. I laid out how to diagnose out of memory issues with Solr in an older post [here](/2017/12/18/ambari-infra-solr-ranger.html). It contains details about where to look as well as how to analyze a heap dump. 

### Conclusion
Using Apache Solr capabilities you can easily scale search and retrieval to larger result sets. DocValues and `/export` handler both enable the [Streaming Expressions](https://lucene.apache.org/solr/guide/7_5/streaming-expressions.html) and [Parallel SQL](https://lucene.apache.org/solr/guide/7_5/parallel-sql-interface.html) features of Solr. This means that the features are well supported and continue to be improved overtime.


**References**

Some related blogs that may be useful for future reading:
* [https://blog.trifork.com/2011/10/27/introducing-lucene-index-doc-values/](https://blog.trifork.com/2011/10/27/introducing-lucene-index-doc-values/)
* [http://blog.florian-hopf.de/2014/05/solr-cache-sizes-eclipse-memory-analyzer.html](http://blog.florian-hopf.de/2014/05/solr-cache-sizes-eclipse-memory-analyzer.html)
* [https://medium.com/@sarkaramrit2/frequent-out-of-memory-errors-in-apache-solr-36499f84c98a](https://medium.com/@sarkaramrit2/frequent-out-of-memory-errors-in-apache-solr-36499f84c98a)
* [https://wiki.apache.org/solr/SolrPerformanceProblems](https://wiki.apache.org/solr/SolrPerformanceProblems)
* [https://www.elastic.co/guide/en/elasticsearch/guide/current/_deep_dive_on_doc_values.html](https://www.elastic.co/guide/en/elasticsearch/guide/current/_deep_dive_on_doc_values.html)
