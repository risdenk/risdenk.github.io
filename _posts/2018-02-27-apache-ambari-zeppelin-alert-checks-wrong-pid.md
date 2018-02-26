---
title: Apache Ambari - Zeppelin Alert Checks Wrong PID
date: 2018-02-27 12:00:00 -06:00
tags:
- bigdata
- apache
- ambari
- zeppelin
- alert
layout: post
---

### Overview
[Apache Ambari](https://ambari.apache.org/) makes managing distributed systems like [Apache Hadoop](https://hadoop.apache.org/) easier. One of the capabilities of Ambari is alerting. These alerts can alert administrators and trigger automatic recovery. Ambari can manage [Apache Zeppelin](https://zeppelin.apache.org/). This management includes starting, stopping, and alert when Zeppelin stops.

### Apache Zeppelin Alert Check False Alarms
Over the course of a few weeks, my team received multiple alerts pointing to Apache Zepplin stopping. We investigated and found that Apache Zeppelin had never stopped and these were false alarms. When alerts go off for false alarms, it reduces the confidence in the alerting system.

### Root Cause of Apache Zeppelin Alert Check False Alarms
I tracked down the cause of the false alarms to be Ambari checking the wrong PID file. Apache Zeppelin creates multiple PID files:
* Apache Zeppelin process
* Each Zeppelin interpreter

Apache Ambari uses `glob.glob(...)` to search for PID files for alerting. In our case, Apache Zeppelin runs as the `zeppelin` user. The Apache Zeppelin interpreters have PID files that ends up being alphabetically before the Apache Zeppelin process PID file.

```bash
ls -l /var/run/zeppelin/
-rw-r--r-- 1 zeppelin hadoop 7 Jan 16 12:01 zeppelin-interpreter-livy-zeppelin-HOSTNAME.pid
-rw-r--r-- 1 zeppelin hadoop 7 Jan 16 11:56 zeppelin-zeppelin-HOSTNAME.pid
```

The Apache Ambari alert check ([0.6.0](https://github.com/apache/ambari/blob/trunk/ambari-server/src/main/resources/common-services/ZEPPELIN/0.6.0/package/scripts/alert_check_zeppelin.py) and [0.7.0](https://github.com/apache/ambari/blob/trunk/ambari-server/src/main/resources/common-services/ZEPPELIN/0.7.0/package/scripts/alert_check_zeppelin.py)) is not checking the Apache Zeppelin process PID specifically. Instead, it relies on the order of PID files in the `zeppelin_dir_dir`.

```python
pid_file = glob.glob(zeppelin_pid_dir + '/zeppelin-*.pid')[0]
```

If an interpreter is stopped (which can happen in normal circumstances) then the Ambari alert will trigger incorrectly even when the Apache Zeppelin process is running. The Ambari Agent logs showed the wrong PID file being checked.

```
INFO 2018-01-16 16:00:05,500 logger.py:75 - Process with pid 257987 is not running. Stale pid file at /var/run/zeppelin/zeppelin-interpreter-livy-zeppelin-HOSTNAME.pid
ERROR 2018-01-16 16:00:05,501 script_alert.py:123 - [Alert][zeppelin_server_status] Failed with result CRITICAL: ['']
```

### What is next?
In late January 2017, I created [AMBARI-22834](https://issues.apache.org/jira/browse/AMBARI-22834) to raise awareness of this issue. Recently, @matthias created [PR 304](https://github.com/apache/ambari/pull/304) to address this issue. We are waiting on an Apache Ambari committer to review and commit this change. Until then we have made the adjustments to the Apache Ambari Apache Zeppelin alert locally to reduce the false alarms.

