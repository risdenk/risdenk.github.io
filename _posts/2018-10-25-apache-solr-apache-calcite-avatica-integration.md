---
title: Apache Solr - Apache Calcite Avatica Integration
date: 2018-10-25 09:00:00 -05:00
tags:
- bigdata
- apache
- solr
- calcite
- avatica
- integration
layout: post
---

### Overview
[Apache Solr](https://lucene.apache.org/solr) is a full text search engine that is built on [Apache Lucene](https://lucene.apache.org/solr/). One of the capabilities of Apache Solr is to handle SQL like statements. This was introduced in Solr 6.0 and refined in subsequent releases. Initially the SQL support used the [Presto SQL parser](https://github.com/prestodb/presto/blob/master/presto-parser/src/main/java/com/facebook/presto/sql/parser/SqlParser.java). This was replaced by [Apache Calcite](https://calcite.apache.org/) due to Presto not having an optimizer. Calcite provides the ability to push down execution of SQL to Apache Solr. 

[Apache Calcite Avatica](https://calcite.apache.org/avatica/) is a subproject of Apache Calcite and provides a JDBC driver as well as JDBC server. The Avatica architecture diagram displays how this fits together.

<p style="text-align:center"><img width="60%" src="https://raw.githubusercontent.com/julianhyde/share/master/slides/avatica-architecture.png" /></p>

### Apache Solr and Apache Calcite Avatica
Apache Solr has historically built its own JDBC driver implementation. This takes quite a bit of effort since the JDBC specification has a lot of methods that need to be implemented. [SOLR-9963](https://issues.apache.org/jira/browse/SOLR-9963) was created to try to integrate Apache Calcite Avatica into Solr. This would provide an endpoint for the Avatica JDBC driver and remove the need for a separate Apache Solr JDBC driver implementation.

### Integrating Apache Calcite Avatica as an Apache Solr Handler
Since Apache Calcite Avatica is implemented in Jetty just like Apache Solr, I had the idea to add Avatica as just another handler in Solr. This would expose all the features of Avatica without changing any internals of Solr. The Avatica handler could then use the existing Calcite engine within Apache Solr to handle the queries.

I created [SOLR-9963](https://issues.apache.org/jira/browse/SOLR-9963) and by early February 2017 I had a working example of the integration of Avatica and Solr. I was able to use the existing Avatica JDBC driver directly with Apache Solr without any issues. Sadly I haven't had time to finish merging this change yet.

### Testing Apache Solr with Apache Calcite Avatica Handler
One of the cool features of Apache Calcite Avatica is that you can interact with it over pure REST with a JSON payload. I created a simple test script to show how this was possible even with Apache Solr.

`./test_avatica_solr.sh "http://localhost:8983/solr/test/avatica" "select * from test limit 10"`

**test_avatica_solr.sh**
```bash
#!/usr/bin/env bash

set -u
#set -x

AVATICA=$1
SQL=$2

CONNECTION_ID="conn-$(whoami)-$(date +%s)"
MAX_ROW_COUNT=100
NUM_ROWS=2
OFFSET=0

echo "Open connection"
curl -i -w "\n" "$AVATICA" -H "Content-Type: application/json" --data "{\"request\": \"openConnection\",\"connectionId\": \"${CONNECTION_ID}\"}"

# Example of how to set connection properties with info key
#curl -i "$AVATICA" -H "Content-Type: application/json" --data "{\"request\": \"openConnection\",\"connectionId\": \"${CONNECTION_ID}\",\"info\": {\"zk\": \"$ZK\",\"lex\": \"MYSQL\"}}"
echo

echo "Create statement"
STATEMENTRSP=$(curl -s "$AVATICA" -H "Content-Type: application/json" --data "{\"request\": \"createStatement\",\"connectionId\": \"${CONNECTION_ID}\"}")
STATEMENTID=$(echo "$STATEMENTRSP" | jq .statementId)
echo

echo "PrepareAndExecuteRequest"
curl -i -w "\n" "$AVATICA" -H "Content-Type: application/json" --data "{\"request\": \"prepareAndExecute\",\"connectionId\": \"${CONNECTION_ID}\",\"statementId\": $STATEMENTID,\"sql\": \"$SQL\",\"maxRowCount\": ${MAX_ROW_COUNT}, \"maxRowsInFirstFrame\": ${NUM_ROWS}}"
echo

# Loop through all the results
ISDONE=false
while ! $ISDONE; do
  OFFSET=$((OFFSET + NUM_ROWS))
  echo "FetchRequest - Offset=$OFFSET"
  FETCHRSP=$(curl -s "$AVATICA" -H "Content-Type: application/json" --data "{\"request\": \"fetch\",\"connectionId\": \"${CONNECTION_ID}\",\"statementId\": $STATEMENTID,\"offset\": ${OFFSET},\"fetchMaxRowCount\": ${NUM_ROWS}}")
  echo "$FETCHRSP"
  ISDONE=$(echo "$FETCHRSP" | jq .frame.done)
  echo
done

echo "Close statement"
curl -i -w "\n" "$AVATICA" -H "Content-Type: application/json" --data "{\"request\": \"closeStatement\",\"connectionId\": \"${CONNECTION_ID}\",\"statementId\": $STATEMENTID}"
echo

echo "Close connection"
curl -i -w "\n" "$AVATICA" -H "Content-Type: application/json" --data "{\"request\": \"closeConnection\",\"connectionId\": \"${CONNECTION_ID}\"}"
echo
```

### What is next?
If this feature looks interesting it would be good to add your thoughts to [SOLR-9963](https://issues.apache.org/jira/browse/SOLR-9963). If there is interest then we can work towards getting SOLR-9963 merged. The Apache Solr JDBC driver would need to then switch to wrapping an Avatica JDBC driver. Overall this should improve the SQL experience that comes with Apache Solr.

