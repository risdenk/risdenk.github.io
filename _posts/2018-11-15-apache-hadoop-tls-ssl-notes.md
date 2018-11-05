---
title: Apache Hadoop - TLS and SSL Notes
date: 2018-11-15 08:00:00 -06:00
tags:
- bigdata
- apache
- hadoop
- tls
- ssl
- security
- openssl
- certificate
- poodle
- heartbleed
layout: post
---

### Overview
I've collected notes on [TLS/SSL](https://en.wikipedia.org/wiki/Transport_Layer_Security) for a number of years now. Most of them are related to [Apache Hadoop](https://hadoop.apache.org/), but others are more general. I was consulting when the [POODLE](https://en.wikipedia.org/wiki/POODLE) and [Heartbleed](https://en.wikipedia.org/wiki/Heartbleed) vulnerabilities were released. Below is a collection of TLS/SSL related references. No guarantee they are up to date but it helps to have references in one place.

### TLS/SSL General
* Great explaination of TLS/SSL: [http://www.zytrax.com/tech/survival/ssl.html](http://www.zytrax.com/tech/survival/ssl.html)
* SSL Linux certificate location: [http://serverfault.com/questions/62496/ssl­certificate­location­on­unix­linux](http://serverfault.com/questions/62496/ssl­certificate­location­on­unix­linux)
* SSL vs TLS: [http://security.stackexchange.com/questions/5126/whats­the­difference­between­ssl­tls­and­https](http://security.stackexchange.com/questions/5126/whats­the­difference­between­ssl­tls­and­https)

### Certificate Types
* [http://unmitigatedrisk.com/?p=381](http://unmitigatedrisk.com/?p=381)
* [http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cm_sg_guide_ssl_certs.html](http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/cm_sg_guide_ssl_certs.html)

### Generating Certificates
* [https://www.sslshopper.com/article-most-common-openssl-commands.html](https://www.sslshopper.com/article-most-common-openssl-commands.html)
* [https://support.ssl.com/Knowledgebase/Article/View/19/0/der-vs-crt-vs-cer-vs-pem-certificates-and-how-to-convert-them](https://support.ssl.com/Knowledgebase/Article/View/19/0/der-vs-crt-vs-cer-vs-pem-certificates-and-how-to-convert-them)

### Existing Certificate and Key to JKS
* [http://stackoverflow.com/questions/11952274/how­can­i­create­keystore­from­an­existing­certificate­abc­crt­and­abc­key­fil](http://stackoverflow.com/questions/11952274/how­can­i­create­keystore­from­an­existing­certificate­abc­crt­and­abc­key­fil)

```bash
openssl pkcs12 ‐export ‐in abc.crt ‐inkey abc.key ‐out abc.p12
keytool ‐importkeystore ‐srckeystore abc.p12 \
        ‐srcstoretype PKCS12 \
        ‐destkeystore abc.jks \
        ‐deststoretype JKS
```

### Trusting CA Certificates
#### OpenSSL
```
update‐ca‐trust force‐enable
cp CERT.pem /etc/pki/tls/source/anchors/
update‐ca‐trust extract
```

#### OpenLDAP
`vi /etc/openldap/ldap.conf`

```
...
TLS_CAFILE /etc/pki/
# Comment out TLS_CERTDIR
...
```

#### Java
```
/usr/java/JAVA_VERSION/jre/lib/security/cacerts
/etc/pki/ca‐trust/extracted/java/cacerts
```

* [https://bugzilla.redhat.com/show_bug.cgi?id=1056224](https://bugzilla.redhat.com/show_bug.cgi?id=1056224)

### POODLE ­ SSLv3
#### What is POODLE?
* [https://poodle.io/servers.html](https://poodle.io/servers.html)
* [https://www.openssl.org/docs/apps/ciphers.html#SSL­v3.0­cipher­suites](https://www.openssl.org/docs/apps/ciphers.html#SSL­v3.0­cipher­suites)

#### Testing for POODLE
* [https://chrisburgess.com.au/how-to-test-for-the-sslv3-poodle-vulnerability/](https://chrisburgess.com.au/how-to-test-for-the-sslv3-poodle-vulnerability/)

```
# Requires a relatively recent version of openssl installed
openssl s_client ‐connect HOST:PORT ‐ssl3
# ‐tls1 ‐tls1_1 ‐tls1_2
curl ‐v3 ‐i ‐X HEAD https://HOST:PORT
```

### Configuring Hadoop for Cipher Suites and Protocols
Each Hadoop component must be configured or have the proper version to disable certain SSL protocols and versions.

#### Ambari
* [https://docs.hortonworks.com/HDPDocuments/HDP3/HDP-3.0.1/configuring-advanced-security-options-for-ambari/content/ambari_sec_optional_configure_ciphers_and_protocols_for_ambari_server.html](https://docs.hortonworks.com/HDPDocuments/HDP3/HDP-3.0.1/configuring-advanced-security-options-for-ambari/content/ambari_sec_optional_configure_ciphers_and_protocols_for_ambari_server.html)
    * `security.server.disabled.ciphers=TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA`
    * `security.server.disabled.protocols=SSL|SSLv2|SSLv3`

#### Hadoop
* [https://issues.apache.org/jira/browse/HADOOP-11243](https://issues.apache.org/jira/browse/HADOOP-11243)
    * Hadoop 2.5.2 + 2.6 ­ Patches SSLFactory for TLSv1
    * `hadoop.ssl.enabled.protocols=TLSv1`
    * (JDK6 can use TLSv1, JDK7+ can use TLSv1,TLSv1.1,TLSv1.2)
* [https://issues.apache.org/jira/browse/HADOOP-11218](https://issues.apache.org/jira/browse/HADOOP-11218)
    * Hadoop 2.8 ­ Patches SSLFactory for TLSv1.1 and TLSv1.2
    * Java 6 doesn't support TLSv1.1+. Requires Java 7.
* [https://issues.apache.org/jira/browse/HADOOP-11260](https://issues.apache.org/jira/browse/HADOOP-11260)
    * Hadoop 2.5.2 + 2.6 ­ Patches Jetty to disable SSLv3

#### HTTPFS
* [https://issues.apache.org/jira/browse/HDFS-7274](https://issues.apache.org/jira/browse/HDFS-7274)
    * Hadoop 2.5.2 + 2.6 ­ Disables SSLv3 in HTTPFS

#### Hive
* [https://issues.apache.org/jira/browse/HIVE-8675](https://issues.apache.org/jira/browse/HIVE-8675)
    * Hive 0.14 ­ Removes SSLv3 from supported protocols
    * `hive.ssl.protocol.blacklist`
* [https://issues.apache.org/jira/browse/HIVE-8827](https://issues.apache.org/jira/browse/HIVE-8827)
    * Hive 1.0 ­ Adds `SSLv2Hello` back to supported protocols
    * `hive.ssl.protocol.blacklist=SSLv2,SSLv3`

#### Oozie
* [https://issues.apache.org/jira/browse/OOZIE-2034](https://issues.apache.org/jira/browse/OOZIE-2034)
    * Oozie 4.1.0 ­ Disable SSLv3
* [https://issues.apache.org/jira/browse/OOZIE-2037](https://issues.apache.org/jira/browse/OOZIE-2037)
    * Add support for TLSv1.1 and TLSv1.2
    * Java 6 doesn't support TLSv1.1+. Requires Java 7. Depends on OOZIE­2036

#### Flume
* [https://issues.apache.org/jira/browse/FLUME-2520](https://issues.apache.org/jira/browse/FLUME-2520)
    * Flume 1.5.1 ­ HTTPSource disable SSLv3

#### Hue
* [https://issues.cloudera.org/browse/HUE-2438](https://issues.cloudera.org/browse/HUE-2438)
    * Hue 3.8 ­ Disable SSLv3
    * line 1670 of `/usr/lib/hue/desktop/core/src/desktop/lib/wsgiserver.py`
    * `ctx.set_options(SSL.OP_NO_SSLv2 | SSL.OP_NO_SSLv3)`
    * `ssl_cipher_list = "DEFAULT:!aNULL:!eNULL:!LOW:!EXPORT:!SSLv2"` (default)

#### Ranger
* [https://issues.apache.org/jira/browse/RANGER-158](https://issues.apache.org/jira/browse/RANGER-158)
    * Ranger 0.4.0 ­ Ranger Admin and User Authentication disable SSLv3

#### Knox
* [https://issues.apache.org/jira/browse/KNOX-455](https://issues.apache.org/jira/browse/KNOX-455)
     * Knox 0.5.0 ­ Disable SSLv3
     * `ssl.exclude.protocols`

#### Storm
* [https://issues.apache.org/jira/browse/STORM-640](https://issues.apache.org/jira/browse/STORM-640)
    * Storm 0.10.0 ­ Disable SSLv3

### Resources
* [http://sysadvent.blogspot.co.uk/2010/12/day-3-debugging-ssltls-with-openssl1.html](http://sysadvent.blogspot.co.uk/2010/12/day-3-debugging-ssltls-with-openssl1.html)
* [https://gist.github.com/jankronquist/6412839](https://gist.github.com/jankronquist/6412839)

