---
title: TODO - Apache Livy - Apache Spark spark-submit Conversion
date: 2018-10-29 17:47:13.234000000 -05:00
tags:
- bigdata
- apache
- livy
- spark
- spark-submit
- conversion
layout: post
---

* https://community.hortonworks.com/articles/151164/how-to-submit-spark-application-through-livy-rest.html
* https://livy.incubator.apache.org/docs/latest/rest-api.html

### Overview
[Apache Livy](https://livy.apache.org/) provides a [REST interface](https://livy.incubator.apache.org/docs/latest/rest-api.html) for interacting with [Apache Spark](https://spark.apache.org/). 

### `spark-submit` Conversion
<textarea id="input" style="width:100%;height:100px" oninput="sparkSubmitConversion()">
./bin/spark-submit \
--class org.apache.spark.examples.SparkPi \
--jars a.jar,b.jar \
--pyFiles a.py,b.py \
--files foo.txt,bar.txt \
--archives foo.zip,bar.tar \
--master yarn \
--deploy-mode cluster \
--driver-memory 10G \
--driver-cores 1 \
--executor-memory 20G \
--executor-cores 3 \
--num-executors 50 \
--queue default \
--name test \
--proxy-user foo \
--conf spark.jars.packages=xxx \
--conf spark.driver.extraClasspath=abc \
/path/to/examples.jar \
1000 \
10
</textarea>

<pre id="result"></pre>

<script type="text/javascript">
var badKeys = ['master', 'deployMode'];

function toCamelCase(str) {
    return str.toLowerCase().replace(/(?:(-+.))/g, function(match) {
        return match.charAt(match.length-1).toUpperCase();
    });
}

function replaceKey(key) {
  key = key.includes('-') ? toCamelCase(key) : key
  return key.replace(/-/g, '');
}

function sparkSubmitConversion() {
  var data = document.getElementById("input").value;
  data = data.replace(/(?:\r\n|\r|\n)/g, ' ').replace(/ \\ /g, ' ');
  data = data.replace(/^.*spark-submit/, '').trim()
  data = data.split(" ");
  
  result = {'args': [], 'conf': {}}; 
  for (len = data.length, i=0; i<len; ++i) {
    datum = data[i];
    if(!datum.trim()) {
      continue;
    }
    if(datum.startsWith('--')) {
      key = replaceKey(datum.replace('--',''));
      if(badKeys.includes(key)) {
        i++;
        continue;
      }
    } else {
      val = datum.includes(',') ? datum.split(',') : datum;
      if(key != null) {
        if(result[key] != null) {
          if(val.includes('=')) { 
            val = val.split('=');
            result[key][val[0]] = val[1];
          } else {
            result[key] = [result[key]];
            result[key].push(val);
          }
        } else {
          result[key] = val;
        }
      } else {
        if(result['file']) {
          result['args'].push(val);
        } else {
          result['file'] = val;
        }
      }
      key = null;
    }
  }

  result = JSON.stringify(result, null, 2);
  document.getElementById("result").innerHTML = result;
}

window.onload=sparkSubmitConversion();
</script>

