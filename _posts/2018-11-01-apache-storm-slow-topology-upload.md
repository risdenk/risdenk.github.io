---
title: Apache Storm - Slow Topology Upload
date: 2018-11-01 09:00:00 -05:00
tags:
- bigdata
- apache
- storm
- topology
- upload
- performance
layout: post
---

**Note:** This is an old post from notes. This may not be applicable anymore but sharing in case it helps someone.

### Overview
[Apache Storm](https://storm.apache.org/) after HDP 2.2 seems to have a hard time with large topology jars and takes a while to upload them. There have been a [few](https://mail-archives.apache.org/mod_mbox/storm-user/201603.mbox/%3CCAPC1M2i3OpKhC3n_+oTJke45Efuxq2PxMVurx71oEU-=Nqd9gQ@mail.gmail.com%3E) [reports](https://community.hortonworks.com/questions/24517/topology­code­distribution­takes­too­much­time.html) of Storm topology jars uploading slowly. I ran into this a few years ago. The fix is to increase the `nimbus.thrift.max_buffer_size` setting.

### Fix
Increase `nimbus.thrift.max_buffer_size` from the default of 1048576 to 20485760.

### References
* [https://mail-archives.apache.org/mod_mbox/storm-user/201403.mbox/%3CFC98EE12-4AED-4D06-9917-C449B96EB08A@gmail.com%3E](https://mail-archives.apache.org/mod_mbox/storm-user/201403.mbox/%3CFC98EE12-4AED-4D06-9917-C449B96EB08A@gmail.com%3E)
* [http://stackoverflow.com/questions/27092653/storm-supervisor-connectivity-error-downloading-the-jar-from-nimbus](http://stackoverflow.com/questions/27092653/storm-supervisor-connectivity-error-downloading-the-jar-from-nimbus)
* [https://qnalist.com/questions/4768442/nimbus-fails-after-uploading-topology-reading-too-large-of-frame-size](https://qnalist.com/questions/4768442/nimbus-fails-after-uploading-topology-reading-too-large-of-frame-size)

