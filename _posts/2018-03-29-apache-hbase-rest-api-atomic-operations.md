---
title: Apache HBase - REST API - Atomic Operations
date: 2018-03-29 09:00:00 -05:00
tags:
- bigdata
- apache
- hbase
- rest
- api
- documentation
- improvements
- checkAndPut
- checkAndDelete
layout: post
---

Shout out to @dequanchen who figured out most of the material below.

## Overview
[Apache HBase](https://hbase.apache.org/) provides the ability to perform realtime random read/write access to large datasets. HBase is built on top of [Apache Hadoop](https://hadoop.apache.org/) and can scale to billions of rows and millions of columns. One of the capabilities of Apache HBase is a [REST server](https://hbase.apache.org/book.html#_rest) previously called [Stargate](https://wiki.apache.org/hadoop/Hbase/Stargate). This REST server provides the ability to interact with HBase from any programming language. As features get added to HBase, they are they implemented in the REST API.

## Apache HBase and Atomic Operations
Atomic operations in Apache HBase are important since it reduces the amount of round trip calls between the client and server. It also prevents complicated locks that are required if there are multiple clients. Two atomic operations (`checkAndPut` and `checkAndDelete`) were added to the REST server as part of [HBASE-4720](https://issues.apache.org/jira/browse/HBASE-4720). These atomic operations are one of the undocumented features in the REST server. This has been an open HBase JIRA, [HBASE-7129](https://issues.apache.org/jira/browse/HBASE-7129), since November 2012. Recently my team figured out how the atomic operations capability works and will be providing a patch back to the Apache HBase community.

## Using the Apache HBase REST API
The Apache HBase REST API has historically been documented in two places. The [Apache HBase Reference Guide](https://hbase.apache.org/book.html#_using_rest_endpoints) and the [JavaDocs](https://hbase.apache.org/1.2/apidocs/org/apache/hadoop/hbase/rest/package-summary.html). The documentation has been mostly moved to the reference guide for current versions of Apache HBase.

The REST API supports multiple different formats:
* Plain Text - `application/octet-stream`
* XML - `text/xml`
* JSON - `application/json`
* Protocol Buffers - `application/x-protobuf`

Each of these formats can be specified as part of the `Accept` header. This blog post will focus on XML and JSON since they are easiest to work with directly. 

Many of the Apache HBase REST API endpoints require the use of [`base64` encoding](https://en.wikipedia.org/wiki/Base64). `base64` encoding ensures that the data can be transmitted across REST without any issues. Keep in mind that newlines and other characters affect the output of `base64`. Both `checkAndPut` and `checkAndDelete` require that the check value match exactly so be careful to avoid extra characters.

When using the Apache HBase REST APIs the literal value in the URL typically has to match the `base64` encoded value in the request body. The examples in this blog show what values need to be `base64` encoded.

## Example Base64 Encoded Values
The `base64` encoded values below are used in the examples in this blog post.

| Literal Text             | Base64 Encoded                     |
| ------------------------ | ---------------------------------- |
| `rowkey`                 | `cm93a2V5`                         |
| `columnfamily:qualifier` | `Y29sdW1uZmFtaWx5OnF1YWxpZmllcg==` |
| `checkvalue`             | `Y2hlY2t2YWx1ZQ==`                 |
| `newvalue`               | `bmV3dmFsdWU=`                     |

## Apache HBase REST API - checkAndPut
`checkAndPut` checks the value of the latest version of a cell and if there is a match puts new data into the same cell.

### checkAndPut Single Qualifier
This `checkAndPut` call will check a specific qualifier value as specified in the request body and put qualifier value specified in the request body for the rowkey specified in the URL. Below is the HTTP method and endpoint followed by an example request body with explanation. This is followed by specific `curl` examples for XML and JSON.

```
# HTTP Method and Endpoint
PUT http://localhost:8084/namespace:table/rowkey/?check=put

# Example XML Request Body with Explanation
<CellSet>
  <Row key="Base64 Encoded RowKey">
    <Cell column="Base64 column family : qualifer">Base64 new value</Cell>
    <Cell column="Base64 column family : qualifer">Base64 check value</Cell>
  </Row>
</CellSet>
```

**Content-Type: text/xml**
```bash
curl -i -H 'Accept: text/xml' \
  -XPUT 'http://localhost:8084/namespace:table/rowkey/?check=put' \
  -d '
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <CellSet>
    <Row key="cm93a2V5">
      <Cell column="Y29sdW1uZmFtaWx5OnF1YWxpZmllcg==">bmV3dmFsdWU=</Cell>
      <Cell column="Y29sdW1uZmFtaWx5OnF1YWxpZmllcg==">Y2hlY2t2YWx1ZQ==</Cell>
    </Row>
  </CellSet>'
```

**Content-Type: application/json**
```bash
curl -i -H 'Accept: application/json' \
  -XPUT 'http://localhost:8084/namespace:table/rowkey/?check=put' \
  -d '
  {
    "Row": [
      {
        "key": "cm93a2V5",
        "Cell": [
          {"column": "Y29sdW1uZmFtaWx5OnF1YWxpZmllcg==", "$": "bmV3dmFsdWU="},
          {"column": "Y29sdW1uZmFtaWx5OnF1YWxpZmllcg==", "$": "Y2hlY2t2YWx1ZQ=="}
        ]
      }
    ]
  }'
```

## Apache HBase REST API - checkAndDelete
`checkAndDelete` checks the value of a cell and if it matches delete the specific version of a qualifier, all versions of a qualifier, column family, or row.

### checkAndDelete Qualifier Single Version
This `checkAndDelete` call will check a specific qualifier value as specified in the request body and delete the single version of the qualifier specified in the URL. Below is the HTTP method and endpoint followed by an example request body with explanation. This is followed by specific `curl` examples for XML and JSON.

```
# HTTP Method and Endpoint
DELETE http://localhost:8084/namespace:table/rowkey/columnfamily:qualifier/version/?check=delete

# Example XML Request Body with Explanation
<CellSet>
  <Row key="Base64 Encoded RowKey">
    <Cell column="Base64 column family : qualifer">Base64 check value</Cell>
  </Row>
</CellSet>
```

**Content-Type: text/xml**
```bash
curl -i -H 'Accept: text/xml' \
  -XDELETE 'http://localhost:8084/namespace:table/rowkey/columnfamily:qualifier/version/?check=delete' \
  -d '
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <CellSet>
    <Row key="cm93a2V5">
      <Cell column="Y29sdW1uZmFtaWx5OnF1YWxpZmllcg==">Y2hlY2t2YWx1ZQ==</Cell>
    </Row>
  </CellSet>'
```

**Content-Type: application/json**
```bash
curl -i -H 'Accept: application/json' \
  -XDELETE 'http://localhost:8084/namespace:table/rowkey/columnfamily:qualifier/version/?check=delete' \
  -d '
  {
    "Row": [
      {
        "key": "cm93a2V5",
        "Cell": [
          {"column": "Y29sdW1uZmFtaWx5OnF1YWxpZmllcg==", "$": "Y2hlY2t2YWx1ZQ=="}
        ]
      }
    ]
  }'
```

### checkAndDelete Qualifier All Versions
This `checkAndDelete` call will check a specific qualifier value as specified in the request body and delete all the versions of a qualifier specified in the URL. Below is the HTTP method and endpoint followed by an example request body with explanation. This is followed by specific `curl` examples for XML and JSON.

```
# HTTP Method and Endpoint
DELETE http://localhost:8084/namespace:table/rowkey/columnfamily:qualifier/?check=delete

# Example XML Request Body with Explanation
<CellSet>
  <Row key="Base64 Encoded RowKey">
    <Cell column="Base64 column family : qualifer">Base64 check value</Cell>
  </Row>
</CellSet>
```

**Content-Type: text/xml**
```bash
curl -i -H 'Accept: text/xml' \
  -XDELETE 'http://localhost:8084/namespace:table/rowkey/columnfamily:qualifier/?check=delete' \
  -d '
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <CellSet>
    <Row key="cm93a2V5">
      <Cell column="Y29sdW1uZmFtaWx5OnF1YWxpZmllcg==">Y2hlY2t2YWx1ZQ==</Cell>
    </Row>
  </CellSet>'
```

**Content-Type: application/json**
```bash
curl -i -H 'Accept: application/json' \
  -XDELETE 'http://localhost:8084/namespace:table/rowkey/columnfamily:qualifier/?check=delete' \
  -d '
  {
    "Row": [
      {
        "key": "cm93a2V5", 
        "Cell": [
          {"column": "Y29sdW1uZmFtaWx5OnF1YWxpZmllcg==", "$": "Y2hlY2t2YWx1ZQ=="}
        ]
      }
    ]
  }'
```

### checkAndDelete Column Family
This `checkAndDelete` call will check a specific qualifier value as specified in the request body and delete the column family specified in the URL. Below is the HTTP method and endpoint followed by an example request body with explanation. This is followed by specific `curl` examples for XML and JSON.

```
# HTTP Method and Endpoint
DELETE http://localhost:8084/namespace:table/rowkey/columnfamily/?check=delete

# Example XML Request Body with Explanation
<CellSet>
  <Row key="Base64 Encoded RowKey">
    <Cell column="Base64 column family : qualifer">Base64 check value</Cell>
  </Row>
</CellSet>
```

**Content-Type: text/xml**
```bash
curl -i -H 'Accept: text/xml' \
  -XDELETE 'http://localhost:8084/namespace:table/rowkey/columnfamily/?check=delete' \
  -d '
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <CellSet>
    <Row key="cm93a2V5">
      <Cell column="Y29sdW1uZmFtaWx5OnF1YWxpZmllcg==">Y2hlY2t2YWx1ZQ==</Cell>
    </Row>
  </CellSet>'
```

**Content-Type: application/json**
```bash
curl -i -H 'Accept: application/json' \
  -XDELETE 'http://localhost:8084/namespace:table/rowkey/columnfamily/?check=delete' \
  -d '
  {
    "Row": [
      {
        "key": "cm93a2V5",
        "Cell": [
          {"column": "Y29sdW1uZmFtaWx5OnF1YWxpZmllcg==", "$": "Y2hlY2t2YWx1ZQ=="}
        ]
      }
    ]
  }'
```

### checkAndDelete Row
This `checkAndDelete` call will check a specific qualifier value as specified in the request body and delete the row specified in the URL. Below is the HTTP method and endpoint followed by an example request body with explanation. This is followed by specific `curl` examples for XML and JSON.

```
# HTTP Method and Endpoint
DELETE http://localhost:8084/namespace:table/rowkey/?check=delete

# Example XML Request Body with Explanation
<CellSet>
  <Row key="Base64 Encoded RowKey">
    <Cell column="Base64 column family : qualifer">Base64 check value</Cell>
  </Row>
</CellSet>
```

**Content-Type: text/xml**
```bash
curl -i -H 'Accept: text/xml' \
  -XDELETE 'http://localhost:8084/namespace:table/rowkey/?check=delete' \
  -d '
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <CellSet>
    <Row key="cm93a2V5">
      <Cell column="Y29sdW1uZmFtaWx5OnF1YWxpZmllcg==">Y2hlY2t2YWx1ZQ==</Cell>
    </Row>
  </CellSet>'
```

**Content-Type: application/json**
```bash
curl -i -H 'Accept: application/json' \
  -XDELETE 'http://localhost:8084/namespace:table/rowkey/?check=delete' \
  -d '
  {
    "Row": [
      {
        "key": "cm93a2V5",
        "Cell": [
          {"column": "Y29sdW1uZmFtaWx5OnF1YWxpZmllcg==", "$": "Y2hlY2t2YWx1ZQ=="}
        ]
      }
    ]
  }'
```

## What is next?
As stated above, my team will be putting together a documentation patch for [HBASE-7129](https://issues.apache.org/jira/browse/HBASE-7129) to improve the HBase REST server documentation. Besides `checkAndPut` and `checkAndDelete` the REST API supports `CheckAndMutate`, `IncrementColumnValue`, and `AppendValue`. These three endpoints aren't supported in the version of HBase we use and also aren't documented. If we upgrade we may look at them. We hope others will benefit from this capability since the atomic operations support has been in the REST API for over 5 years now.

