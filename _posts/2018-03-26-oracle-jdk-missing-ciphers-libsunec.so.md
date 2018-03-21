---
title: Oracle JDK - Missing Ciphers - libsunec.so
date: 2018-03-26 09:00:00 -05:00
tags:
- bigdata
- oracle
- jdk
- jre
- ciphers
- tls
- ssl
- libsunec.so
layout: post
---

Shout out to @quirogadf who dug in and found much of the information below.

### Overview
The Oracle JDK supports a certain set of ciphers and protocols based on the JDK version and if the [Java Cryptography Extension](http://www.oracle.com/technetwork/java/javase/downloads/jce8-download-2133166.html) is installed. With Java 8 and 9, there have been recent changes to the JCE requirements with it being [installed and enabled by default](https://golb.hplar.ch/2017/10/JCE-policy-changes-in-Java-SE-8u151-and-8u152.html). While working with many Java projects including [Apache Hadoop](https://hadoop.apache.org/) and [Elasticsearch](https://www.elastic.co/products/elasticsearch), we wanted to ensure that strong ciphers were used for TLS/SSL. While trying to enable the strong ciphers, we found that our vendor installed JDK did not seem to support these ciphers.

### Evaluating Supported JDK Ciphers
The following `jrunscript` command will output what ciphers are supported for TLS/SSL.
```bash
jrunscript -e "print(java.util.Arrays.toString(javax.net.ssl.SSLServerSocketFactory.getDefault().getSupportedCipherSuites()))"
```

### Comparing Supported vs Expected Ciphers
For one of our nodes, we noticed that the out of the above command was as follows:
```
[TLS_RSA_WITH_AES_256_CBC_SHA256, TLS_DHE_RSA_WITH_AES_256_CBC_SHA256, TLS_DHE_DSS_WITH_AES_256_CBC_SHA256, TLS_RSA_WITH_AES_256_CBC_SHA,....
```

This was missing the stronger ciphers that we were interested in like the [elliptic-curve cryptography](https://en.wikipedia.org/wiki/Elliptic-curve_cryptography) ciphers. The specific ciphers were we looking for are:
* `TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256`
* `TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256`
* `TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA`
* `TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA`

### Finding the Missing Ciphers 
Since we were not running the latest JDK 8 release, we needed to check that we had properly installed the JCE. The script below will make check if the JCE is installed based on the supported key length.

```bash
jrunscript -e 'exit (javax.crypto.Cipher.getMaxAllowedKeyLength("RC5") >= 256);' || if [ $? -eq 1 ]; then echo "JCE Installed"; else echo "JCE Not Installed or Error"; fi
```

The JCE was properly installed, but we were still not able to list all the ECC ciphers. We installed a separate Oracle JDK to see if this was a problem with the existing JDK install. We found that with the new JDK install, all the ciphers were available. This pointed to the JDK that was installed by our vendor being different than a standard JDK install.

We compared the files in the vendor installed JDK and the standard Oracle JDK. After some effort, we found that `libsunec.so` was missing. Without `libsunec.so`, certain ciphers are not available including the ECC ciphers. We found that if the native library is not available, then these ciphers are not available. 

> [...] The Java classes are packaged into the signed sunec.jar in the JRE extensions directory and the C++ and C functions are packaged into libsunec.so or sunec.dll in the JRE native libraries directory. If the native library is not present then this provider is registered with support for fewer ECC algorithms (KeyPairGenerator, Signature and KeyAgreement are omitted).

### Adding `libsunec.so` and Checking Ciphers
We copied `libsunec.so` from the standard Oracle JDK to the vendor installed JDK location and rechecked the available ciphers.

```
jrunscript -e "print(java.util.Arrays.toString(javax.net.ssl.SSLServerSocketFactory.getDefault().getSupportedCipherSuites()))"
[TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384, TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384, TLS_RSA_WITH_AES_256_CBC_SHA256, TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384, TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384, TLS_DHE_RSA_WITH_AES_256_CBC_SHA256, TLS_DHE_DSS_WITH_AES_256_CBC_SHA256, TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA, TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA, TLS_RSA_WITH_AES_256_CBC_SHA,...
```

As the output above shows, after copying `libsunec.so` we were able to confirm that the strong ciphers were available. We contacted our vendor to ensure that the JDK is packaged correctly with `libsunec.so`. We have copied `libsunec.so` to the vendor JDK location and are currently using the stronger ciphers as desired.

