---
title: Apache Hadoop S3A With Hitachi Content Platform (HCP)
date: 2018-03-27 09:00:00 -05:00
tags:
- bigdata
- apache
- hadoop
- s3
- s3a
- hitachi
- content
- platform
- HCP
layout: post
---

Big shoutout to @quirogadf for digging into this and Hitachi for a quick turnaround in finding the root cause of the 405 error.

### Overview
The [Hitachi Content Platform (HCP)](https://www.hitachivantara.com/en-us/products/cloud-object-platform/content-platform.html) is a storage device that has multiple APIs (NFS, CIFS, REST, WebDAV, and S3 compatible). Since one of the the APIs is an [S3 compatible endpoint](https://knowledge.hds.com/Documents/Storage/Content_Platform/7.1.2/Manage_an_HCP_system/Using_Hitachi_API_for_Amazon_S3), we wanted to test if we could integrate our existing [Apache Hadoop](https://hadoop.apache.org/) copies with the HCP. We leverage [`distcp`](https://hadoop.apache.org/docs/stable/hadoop-distcp/DistCp.html) for our copies both directly and indirectly. With Hadoop [supporting S3 compatible endppints](https://hadoop.apache.org/docs/stable/hadoop-aws/tools/hadoop-aws/index.html), we set out to see how it would work with HCP. 

### History of Apache Hadoop S3 Support
#### `s3://` Filesystem
Apache Hadoop originally supported S3 with the [`s3://` filesystem](https://hadoop.apache.org/docs/stable/hadoop-aws/tools/hadoop-aws/index.html#S3). It uses blob storage and only works with applications that support that. This filesystem will be removed in Hadoop 3 and is not recommended anymore.

#### `s3n://` Filesystem
After the `s3://` filesystem, Apache Hadoop developed the [`s3n://` filesystem](https://hadoop.apache.org/docs/stable/hadoop-aws/tools/hadoop-aws/index.html#S3N). The `s3n://` filesystem supports native S3 objects and is supported for th entire Hadoop 2.x line. Even with the many improvements over the original `s3://` filesystem, there are still multiple problems that make it unusable in many cases. It is not recommended to use `s3n://` filesystem and instead move to the `s3a://` filesystem.

#### `s3a://` Filesystem
The [`s3a://` filesystem](https://hadoop.apache.org/docs/stable/hadoop-aws/tools/hadoop-aws/index.html#S3A) is under active development and tries to remove many of the existing limitations of the `s3n://` filesystem. It was first introduced in Hadoop 2.6 and has undergone a lot of development between initial 2.6 release and the latest 2.9.x release. The biggest change is that `s3a://` doesn't rely on the [JetS3t library](http://www.jets3t.org/) anymore and instead uses the native [AWS S3 Java library](https://aws.amazon.com/sdk-for-java/). Another big benefit is that for S3 compatible endpoints, the configuration can be set without changing cluster configurations that require restarts. It is currently recommended to use `s3a://` for interacting with S3 when using Apache Hadoop.

### Testing S3A with HCP 7.x (no multipart support)
Based on the current Apache Hadoop S3 recommendations and improvements to `s3a://` over the existing implementations, we wanted to use `s3a://` with HCP. When we first started testing, HCP 7.x was the version installed. This version did not support S3 multipart which limited the size of data that could be sent. We were able to connect HCP with `s3a://` with a few simple configuration items:
* `fs.s3a.access.key`
* `fs.s3a.secret.key`
* `fs.s3a.endpoint`
    * This is the HCP tenant URL (ie: `tenant.HCP_HOSTNAME`)
* `hdfs://NAMESPACE/path`
    * The namespace needs to be setup in HCP with S3 support.

Although we were able to connect and store data with `s3a://` we were eager for HCP 8.x which would add support for S3 multipart.

### Testing S3A with HCP 8.x (with multipart support)
Earlier this year, HCP 8.x was installed which included support for S3 multipart. We were eager to try out multipart since this would support large files and improve performance of large uploads. We initially ran into issues with multipart with Apache Hadoop 2.7.3 and aws-sdk-java version 1.10.6. For files that exceeded the multipart size, resulted in the following error:

```
18/02/12 09:31:12 DEBUG amazonaws.request: Received error response: com.amazonaws.services.s3.model.AmazonS3Exception: HTTP method PUT is not supported by this URL (Service: null;
Status Code: 405; Error Code: 405 HTTP method PUT is not supported by this URL; Request ID: null), S3 Extended Request ID: null
```

We followed the request structure and it matched what the HCP documentation explained it should be. We worked with Hitachi to determine the issue was with the AWS SDK version. According to Hitachi, the `Content-Type` header was incorrectly set in aws-java-sdk-s3 prior to version v1.10.38. Version v1.10.38 corrected the `Content-Type` header to "application/octet-strem". 

We updated the AWS SDK version v1.10.77 and tested `s3a://` with HCP again. We were successfully able to upload files that exceeded 700GB with multipart support which previously failed. Note that updating the AWS SDK version [could result in errors](https://hadoop.apache.org/docs/stable/hadoop-aws/tools/hadoop-aws/index.html#Missing_method_in_com.amazonaws_class) in some cases.

### What is next?
Since HCP 8.x and `s3a://` work together for simple copies with `distcp`, we want to explore using the HCP for other use cases. There are cases where we could pull data from the HCP for processing with other data sets. Checking the integration of HCP, `s3a://`, and something like [Apache Hive](https://hive.apache.org/) is something we will be looking at in the future.

