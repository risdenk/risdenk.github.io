---
title: Apache Ambari - Custom Alert Dispatch Script
date: 2018-03-25 09:00:00 -05:00
tags:
- bigdata
- apache
- ambari
- custom
- alert
- dispatch
- script
layout: post
---

### Overview
[Apache Ambari](https://ambari.apache.org/) makes managing distributed systems like [Apache Hadoop](https://hadoop.apache.org/) easier. One of the capabilities of Ambari is [alerts](https://cwiki.apache.org/confluence/display/AMBARI/Alerts). Ambari monitors the state of the cluster and can alert based on a web endpoint not being available or the output of a custom script. When an alert is triggered, Ambari displays a notification in the UI but also provides the ability to email, SNMP, or call a custom script.

### Integrating Ambari Alerts with External Tools
The [Ambari custom script dispatch](https://cwiki.apache.org/confluence/display/AMBARI/Creating+a+Script-based+Alert+Dispatcher) capability makes it possible to integrate alerts with external tools. We use a custom Python script to dispatch alerts to a shared mailbox and page on call if necessary. This is flexible and the script can be changed after the initial setup without restarting Ambari Server. Another benefit is that the script is called for each alert individually. Alerts are not batched like they are with the built in email notifier.

### Creating a Custom Ambari Alert Dispatcher
The below is adopted from the following [post](https://community.hortonworks.com/content/supportkb/48921/how-to-use-script-based-alert-dispatchers-in-ambar.html) with details added since it wasn't clear what the format of the script should be. We also found that the script API has changed slightly over time adding more parameters to the script (ie: [AMBARI-20291](https://issues.apache.org/jira/browse/AMBARI-20291)).

#### Create the Ambari Custom Alert Dispatcher Script
```python
#!/usr/bin/env python

from datetime import datetime
import sys

def handle_alert():
  '''
  # handle_alert method which is called from Ambari
  # :param definitionName: the alert definition unique ID
  # :param definitionLabel: the human readable alert definition label
  # :param serviceName: the service that the alert definition belongs to
  # :param alertState: the state of the alert (OK, WARNING, etc)
  # :param alertText: the text of the alert
  # :param alertTimestamp: the timestamp the alert went off - Added in AMBARI-20291
  # :param hostname: the hostname the alert fired off for - Added in AMBARI-20291
  '''

  definitionName = sys.argv[1]
  definitionLabel = sys.argv[2]
  serviceName = sys.argv[3]
  alertState = sys.argv[4]
  alertText = sys.argv[5]
  # AMBARI-20291
  if len(sys.argv) == 8:
    alertTimestamp = sys.argv[6]
    hostname = sys.argv[7]
  else:
    alertTimestamp = 'N/A'
    hostname = 'N/A'

  # Generate a timestamp for when this script was called
  timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

  # Add custom logic here to handle the alert

if __name__ == '__main__':
  if len(sys.argv) >= 6:
    handle_alert()
  else:
    print("Incorrect number of arguments")
    sys.exit(1)
```

#### Setup Ambari Alert Target
* `vi /etc/ambari-server/conf/ambari.properties`
    * `my.custom.alert.dispatcher.script=PATH_TO/ambari_custom_alert_dispatcher.py`
* `ambari-server restart`

#### Create Ambari Alert Target
```bash
curl -i \
  -u $(whoami) \
  -H 'X-Requested-By: ambari' \
  -XPOST \
  "https://AMBARI_SERVER_HOST:8443/api/v1/alert_targets" \
  -d '
  {
    "AlertTarget": 
      {
        "name": "my_custom_dispatcher", 
        "description": "My Custom Dispatcher", 
        "notification_type": "ALERT_SCRIPT", 
        "global": true, 
        "alert_states": ["CRITICAL"], 
        "properties": { 
          "ambari.dispatch-property.script": "my.custom.alert.dispatcher.script"
        }
      }
  }
'
```

#### Delete Ambari Alert Target
```bash
curl -i \
  -u $(whoami) \
  -H 'X-Requested-By: ambari' \
  -XDELETE \
  "https://AMBARI_SERVER_HOST:8443/api/v1/alert_targets/ALERT_NUMBER"
```

