---
title: Improving Hue File Browser Avro Performance
date: 2017-12-20 18:00:00 Z
tags:
- bigdata
- hue
- file
- browser
- avro
- performance
layout: post
---

### Background
[Hue](http://gethue.com/) is a user interface for [Hadoop](https://hadoop.apache.org). Part of the benefit of using Hue is the ability to preview files directly in a web browser. The files that are stored on [HDFS](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HdfsDesign.html) are hard to work with when first getting started. The Hue File Browser makes it simple to browse the HDFS file system just as if you were browsing a file on your computer. Hue even supports the ability to view [Avro](https://avro.apache.org/) files natively.

### Hue File Browser Avro Performance Problem
While working with the Hue File Browser, it was noticed that for certain file types it would take upwards of a few minutes to preview a file. At first it was thought that this was just compressed files or large files, but this was determined to be only Avro files. After further debugging, it was found that on small Avro files (<10KB) it would take almost 2 minutes to load a file and this was repeatable. 

I dug into the [Hue codebase](https://github.com/cloudera/hue/) to see if there was something that would only affect Avro files but not text files. During this time, the version of Hue I was working with was 3.9. I also checked Hue 3.11 (latest when investigating) and found that even with the improvements from [HUE-3718](https://issues.cloudera.org/browse/HUE-3718) the File Browser Avro performance wasn't any better.

I noticed that Hue was using the [Avro Python library](https://avro.apache.org/docs/current/gettingstartedpython.html) for parsing the Avro files with the Hue File Browser. The [Avro Python library source code](https://github.com/apache/avro/tree/master/lang/py) provided some insights into why the Hue File Browser performance was terrible with Avro files.

Hue uses [WebHDFS](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/WebHDFS.html), a REST interface to HDFS, when reading files before displaying with the File Browser. The Avro Python library was assuming that `read(1)` calls (read 1 byte of the file) would be sufficiently fast. In the case of WebHDFS, each `read(1)` call resulted in a single network round trip based on the implementation of `read` in [Hue's WebHDFS library](https://github.com/cloudera/hue/blob/master/desktop/libs/hadoop/src/hadoop/fs/webhdfs.py). For a file of 10KB, this would be approximately 10000 network round trips. Even if each round trip is 10ms, this results in a long preview time of 100s or ~1.5 minutes. This matched our experience when previewing even small Avro files.

### Fixing Hue WebHDFS Avro Performance
The performance of the Hue File Browser for Avro files was significantly improved by adjusting how Hue reads from WebHDFS. Hue's WebHDFS library (`webhdfs.py`) typically would request a `DEFAULT_READ_SIZE` of 1MB to reduce network round trips. The Avro Python library was overriding this by requesting `read(1)` which means read 1 byte at a time.

I opened an issue against the Hue GitHub project [here](https://github.com/cloudera/hue/issues/587) and created [HUE-7821](https://issues.cloudera.org/browse/HUE-7821) to raise awareness to this problem. I followed up the issue with a [pull request](https://github.com/cloudera/hue/pull/588/files) to address the underlying performance issue.

The pull request changes Hue's WebHDFS library to ensure that for each `read(...)` call that at least `DEFAULT_READ_SIZE` is requested. This is then cached for a future call to `read`. Only the requested length of data is returned to the caller. By reusing the `self._pos` variable and one new caching variable, the change consisted of less than 20 lines of code and improved performance dramatically.

The `webhdfs.py` code hasn't changed for Hue 2.x, 3.x or 4.x meaning that this minor change could improve the performance across a wide number of releases. Since the code change only affects Python files, this can easily be adjusted on existing Hue installations.

### Performance after the change
With the above change in place, the performance of the Hue File Browser with Avro files was almost instantaneous. The Hue File Browser was able to load small Avro files instantly and larger Avro files (few hundred MB) as fast as the network would allow.

