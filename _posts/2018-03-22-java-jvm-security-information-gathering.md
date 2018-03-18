---
title: Java - JVM Security Information Gathering
date: 2018-03-22 12:00:00 -05:00
tags:
- java
- jvm
- security
- tls
- ssl
- algorithms
- providers
- ciphers
layout: post
---

### Overview
Over the last ~5 years I've worked with quite a few different Hadoop clusters. During this time, Java has changed quite a bit supporting different security features with each version. Additionally, each deployment has different requirements for required security configurations. The examples below show how to quickly grab JVM security configurations from the command line with [`jrunscript`](https://docs.oracle.com/javase/9/tools/jrunscript.htm#JSWOR750). This doesn't require moving JAR files to different machines and can easily be run in many environments. The commands should work from Java 7 through Java 9 at least. Understanding the output of the below commands requires reading the Java security docs some of which are [here](https://docs.oracle.com/javase/9/security/toc.htm), [here](https://docs.oracle.com/javase/9/security/oracleproviders.htm#JSSEC-GUID-F41EE1C9-DD6A-4BAB-8979-EB7654094029), and [here](https://docs.oracle.com/javase/9/docs/specs/security/standard-names.html).
 
### SecureRandom
[`SecureRandom`](https://docs.oracle.com/javase/9/docs/api/java/security/SecureRandom.html) is a class that provides a "cryptographically strong random number generator (RNG)". Depending on the JDK configuration there are varying levels of security and performance. The commands below print out the available provider and algorithm for both standard `SecureRandom()` and `SecureRandom.getInstanceStrong()`. The examples also show how you can tweak the configuration of `SecureRandom` with Java properties.

```bash
jrunscript -e "sr = new java.security.SecureRandom(); print(sr.getProvider() + ' - ' + sr.getAlgorithm())"
jrunscript -Djava.security.egd=file:/dev/./urandom -e "sr = new java.security.SecureRandom(); print(sr.getProvider() + ' - ' + sr.getAlgorithm())"
jrunscript -e "sr = java.security.SecureRandom.getInstanceStrong(); print(sr.getProvider() + ' - ' + sr.getAlgorithm())"
jrunscript -Djava.security.egd=file:/dev/./urandom -e "sr = java.security.SecureRandom.getInstanceStrong(); print(sr.getProvider() + ' - ' + sr.getAlgorithm())"
```

### Security.getAlgorithms()
[`Security.getAlgorithms()`](https://docs.oracle.com/javase/9/docs/api/java/security/Security.html#getAlgorithms-java.lang.String-) returns the available algorithms for the specified service. This can be useful to determine if a required algorithm is supported by the JVM that you are running.

```bash
jrunscript -e "print(java.security.Security.getAlgorithms('SecureRandom'))"
jrunscript -e "print(java.security.Security.getAlgorithms('KeyStore'))"
jrunscript -e "print(java.security.Security.getAlgorithms('Cipher'))"
```

### Security.getProviders()
[`Security.getProviders()`](https://docs.oracle.com/javase/9/docs/api/java/security/Security.html#getProviders--) provides a way to list all the installed providers in order that they will be used by preference. If you had a custom provider or are checking if a standard provider is available, this command can help.

```bash
jrunscript -e "print(java.util.Arrays.toString(java.security.Security.getProviders()))"
```

### TLS/SSL Cipher Suites
With TLS/SSL becoming more important, configuring the JVM with the proper cipher suites is critical. The examples below show what the supported cipher suites are and what cipher suites are enabled by default. This can help debug problems where the server and client expect different cipher suites to be enabled.

```bash
jrunscript -e "print(java.util.Arrays.toString(javax.net.ssl.SSLServerSocketFactory.getDefault().getDefaultCipherSuites()))"
jrunscript -e "print(java.util.Arrays.toString(javax.net.ssl.SSLServerSocketFactory.getDefault().getSupportedCipherSuites()))"
jrunscript -e "print(java.util.Arrays.toString(javax.net.ssl.SSLContext.getDefault().getDefaultSSLParameters().getCipherSuites()))"
jrunscript -e "print(java.util.Arrays.toString(javax.net.ssl.SSLContext.getDefault().getSupportedSSLParameters().getCipherSuites()))"
```

