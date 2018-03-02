---
title: Apache NiFi Multitenancy and Kerberos Keytabs
date: 2018-03-09 12:00:00 -06:00
tags:
- bigdata
- apache
- nifi
- multitenant
- kerberos
- keytab
- security
layout: post
---

### Overview
[Apache NiFi](https://nifi.apache.org/) is "an easy to use, powerful, and reliable system to process and distribute data." [NiFi supports multi tenancy](https://nifi.apache.org/docs/nifi-docs/html/user-guide.html#UI-with-multi-tenant-authorization) where different users can use a single NiFi instance. [Restricted](https://static.javadoc.io/org.apache.nifi/nifi-api/1.5.0/org/apache/nifi/annotation/behavior/Restricted.html) [components](https://docs.hortonworks.com/HDPDocuments/HDF3/HDF-3.0.2/bk_developer-guide/content/restricted.html) are a feature of NiFi that try to identify dangerous components that can have separate authorization policies.

### NiFi Multitenancy and Kerberos Keytabs
[Kerberos](https://web.mit.edu/kerberos/) [keytabs](https://web.mit.edu/kerberos/krb5-1.12/doc/basic/keytab_def.html) are just like passwords in that they need to be protected at all costs. Typically file system permissions are used to secure keytabs and prevent unauthorized access. Since NiFi runs in a single JVM as a single process, this means that a single OS user (typically `nifi`) is used to run a NiFi instance.

Multitenancy NiFi can be dangerous since keytabs are not protected from users of the NiFi instance. Any keytabs on the NiFi instance OS that are accessible by the user running NiFi can also be accessed by the user of NiFi. Even though the contents of the keytab will not be readable, there are components that can use the keytabs.

The components that use keytabs are not all restricted components. This means that there is no way to prevent users from using components that use keytabs. If authorization policies are setup that allow the principal/keytab pair to access resources that the NiFi user would not have access to this could be an issues.

In many cases there is a non keytab replacement for the component that uses keytabs. The username/password properties in NiFi are not shared between users. This would provide the ability to securely use NiFi in a multitenant environment.

### References
#### List of NiFi Restricted Components 
```
nifi git:(master) git grep '@Restricted(' | cut -d':' -f1 | rev | cut -d'/' -f1 | rev | cut -d'.' -f1 | sort -u
DeleteHDFS
DeprecatedProcessor
ExecuteFlumeSink
ExecuteFlumeSource
ExecuteGroovyScript
ExecuteProcess
ExecuteScript
ExecuteStreamCommand
FetchFile
FetchHDFS
FetchParquet
FullyDocumentedControllerService
FullyDocumentedProcessor
FullyDocumentedReportingTask
GetFile
GetHDFS
InvokeScriptedProcessor
PutFile
PutHDFS
PutParquet
RestrictedProcessor
ScriptedLookupService
ScriptedReader
ScriptedRecordSetWriter
ScriptedReportingTask
SiteToSiteBulletinReportingTask
SiteToSiteProvenanceReportingTask
TailFile
```

