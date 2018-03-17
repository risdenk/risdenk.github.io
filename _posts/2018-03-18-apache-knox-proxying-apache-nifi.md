---
title: Apache Knox - Proxying Apache NiFi
date: 2018-03-18 13:00:00 -05:00
tags:
- bigdata
- apache
- knox
- proxy
- nifi
- security
layout: post
---

### TL;DR
There is a working example of Apache Knox and Apache NiFi with Docker [here](https://github.com/risdenk/knox_nifi_testing). For all the details about how to set this up and debugging information keep reading.

## Overview
[Apache Knox](https://knox.apache.org/) is a reverse proxy that simplifies security in front of a Kerberos secured [Apache Hadoop](https://hadoop.apache.org/) cluster and other related components. However, it is not required to have Apache Hadoop to use Knox. One use case for Apache Knox is to provide a single point of entry for disparate components and UIs. Each of these components and UIs can be proxied by Apache Knox.

On the [Apache Knox user mailing list](https://mail-archives.apache.org/mod_mbox/knox-user/) the other day, there was an [interesting post](http://mail-archives.apache.org/mod_mbox/knox-user/201803.mbox/%3CCACSRyKLMP9H--uFRwcGYO4Y0x-hHcgZPe1hc8kgp5Gn8SWi2%3Dw%40mail.gmail.com%3E) about using Apache Knox to connect to [Apache NiFi](https://nifi.apache.org/). The message author was running into multiple TLS/SSL issues between Apache Knox and Apache NiFi. This post describes how to successfully setup Knox to proxy Apache NiFi.

## Apache Knox Support for Apache NiFi
[Apache Knox](https://knox.apache.org) gained support for [Apache NiFi](https://nifi.apache.org) in version 0.14.0 with [KNOX-970](https://issues.apache.org/jira/browse/KNOX-970). The [Knox 0.14.0 user guide](https://knox.apache.org/books/knox-0-14-0/user-guide.html) doesn't have information (yet) about how to setup Knox for proxying NiFi. A prior understanding of how Apache Knox works would help figure out the integration. There is also [some Hortonworks Data Flow (HDF) documentation](https://docs.hortonworks.com/HDPDocuments/HDF3/HDF-3.1.1/bk_security/content/configure_knox_for_nifi.html) from [Hortonworks](https://hortonworks.com/) for setting up Apache Knox with Apache NiFi.

## Setting Up Apache Knox and Apache NiFi
There are multiple components involved to setup Apache Knox and Apache NiFi. The [Apache NiFi TLS Toolkit](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#tls-generation-toolkit) helps create TLS/SSL certificates that work for Apache NiFi as well as integrating Apache Knox. Apache NiFi itself will need to be setup. Finally Apache Knox project will be used as both a demo LDAP server and the proxy server. The guide below walks through setting up Apache NiFi secured with TLS, setting up Apache Knox, and finally integrating Apache Knox with Apache NiFi.

### Assumptions
* Running macOS for browser
* Apache NiFi 1.5.0 on Linux/macOS
* Apache Knox 1.0.0 on Linux/macOS

### Generating SSL/TLS Certificates with Apache NiFi TLS Toolkit
#### Download and Extract Apache NiFi TLS Toolkit
[Download Apache NiFi TLS Toolkit](https://www.apache.org/dyn/closer.lua?path=/nifi/1.5.0/nifi-toolkit-1.5.0-bin.tar.gz) and extract the `.tar.gz` file.
```bash
tar zxvf nifi-toolkit-1.5.0-bin.tar.gz
cd nifi-toolkit-1.5.0
```

#### Generate certificates for Apache NiFi host(s), Apache Knox host(s), and initial admin user
Make sure to fill in the `NIFI_FQDN_HOSTNAME` and the `KNOX_FQDN_HOSTNAME`.
```bash
NIFI_FQDN_HOSTNAME=
./bin/tls-toolkit.sh standalone --hostnames $NIFI_FQDN_HOSTNAME --isOverwrite --trustStorePassword truststore --keyStorePassword nifi --keyStoreType jks

KNOX_FQDN_HOSTNAME=
./bin/tls-toolkit.sh standalone --hostnames $KNOX_FQDN_HOSTNAME --isOverwrite --trustStorePassword truststore --keyStorePassword knox --keyStoreType jks

./bin/tls-toolkit.sh standalone --isOverwrite --clientCertDn CN=nifi-admin,OU=NIFI --clientCertPassword nifi-admin
```

**Note:** The above passwords are NOT secure. This is for demo purposes. Removing the `--keyStorePassword`, `--trustStorePassword`, and `--clientCertPassword` options will make the TLS toolkit generate random passwords.

#### Copy the generated certificates to the correct hosts
For each host that you generated TLS/SSL certificates for, copy the FQDN hostname folder to `/opt/certs/` on the node.

**Note:** If you want to use a different location that is fine just keep track for later.

#### Configure Browser for Apache NiFi TLS/SSL Authentication
Since Apache NiFi uses 2-way SSL, your browser will have to be configure to provide a client SSL certificate. This was generated above as part of the TLS toolkit steps.

The below steps assume you are on macOS. If you aren't then search Google for "import ssl certificate browser".
* Open "Keychain Access"
* Click File -> Import Items
* Import the `CN=nifi-admin_OU=NIFI.p12` file
* Enter the password `nifi-admin` when prompted

### Setting up Apache NiFi
#### Download and Extract Apache NiFi 
[Download Apache NiFi](https://www.apache.org/dyn/closer.lua?path=/nifi/1.5.0/nifi-1.5.0-bin.tar.gz) and extract the `.tar.gz` file.

```bash
tar zxvf nifi-1.5.0-bin.tar.gz
cd nifi-1.5.0
```

#### Configure Apache NiFi for TLS/SSL
Set the following properties in `conf/nifi.properties` replacing `NIFI_FQDN_HOST` with the correct value for your node:
```
nifi.web.http.port=
nifi.web.https.port=9091
nifi.remote.input.secure=true
nifi.cluster.protocol.is.secure=false
nifi.security.keystore=/opt/certs/NIFI_FQDN_HOSTNAME/keystore.jks
nifi.security.keystoreType=JKS
nifi.security.keystorePasswd=nifi
nifi.security.truststore=/opt/certs/NIFI_FQDN_HOSTNAME/truststore.jks
nifi.security.truststoreType=JKS
nifi.security.truststorePassword=truststore
nifi.security.needClientAuth=true
nifi.web.proxy.context.path=gateway/sandbox/nifi-app
```

**Note:** If you let the Apache NiFi TLS Toolkit generate random passwords then they should be specified here instead. If you chose a different location than `/opt/certs` put that here as well.

Set the following in `conf/authorizers.xml`
```
# Line 52
<property name="Initial User Identity 1">CN=nifi-admin, OU=NIFI</property>

# Line 247
<property name="Initial Admin Identity">CN=nifi-admin, OU=NIFI</property>
```

**Note:**
* The space between ", OU" is very important. Apache NiFi is very sensitive to this whitespace.
* If you change the initial admin identity later after starting Apache NiFi, you must delete the generated `conf/users.xml` and `conf/authorizations.xml`.

#### Start Apache NiFi and Check UI
Start Apache NiFi
```bash
./bin/nifi.sh start
```

Open Apache NiFi UI in your browser
* `https://NIFI_HOST:9091/nifi`
    * `NIFI_HOST` - This should be the fully qualified domain name of the `NIFI_HOST`
    * This should prompt for a client certificate, select the `CN=nifi-admin,OU=NIFI` certificate.
 
**Note:** It may take a minute or two for Apache NiFi to start. Check the `logs` directory for more details.

You should see this:

<p style="text-align:center"><img width="600px" src="/images/posts/2018-03-18/nifi_ui.png" /></p>

#### Configure Apache NiFi for Apache Knox 
For Apache Knox to be able to proxy requests to Apache NiFi, there needs to be an Apache Knox user and an authorization policy in Apache NiFi. 

For each of the steps below, replace `KNOX_FQDN_HOSTNAME` with the correct value for your Apache Knox host.

**Add Apache Knox user to Apache NiFi** 
<table>
  <tr>
    <td>Open the Apache NiFi hamburger menu</td>
    <td style="text-align:center"><img width="200px" src="/images/posts/2018-03-18/nifi_ui_hamburger.png" /></td>
  </tr>
  <tr>
    <td>Click "Users"</td>
    <td style="text-align:center"><img width="200px" src="/images/posts/2018-03-18/nifi_ui_users.png" /></td>
  </tr>
  <tr>
    <td>Click the "Add User" icon</td>
    <td style="text-align:center"><img width="700px" src="/images/posts/2018-03-18/nifi_ui_users_add.png" /></td>
  </tr>
  <tr>
    <td>Enter `CN=KNOX_FQDN_HOSTNAME, OU=NIFI` into the "Identity" box and click "OK"</td>
    <td style="text-align:center"><img width="200px" src="/images/posts/2018-03-18/nifi_ui_user_add_KNOX_FQDN_HOSTNAME.png" /></td>
  </tr>
  <tr>
    <td colspan="2">Close the "NiFi Users" dialog with the "X" button.</td>
  </tr>
</table>

**Add Apache NiFi policy to allow Apache Knox user to proxy requests**
<table>
  <tr>
    <td>Open the Apache NiFi hamburger menu</td>
    <td style="text-align:center"><img width="200px" src="/images/posts/2018-03-18/nifi_ui_hamburger.png" /></td>
  </tr>
  <tr>
    <td>Click "Policies"</td>
    <td style="text-align:center"><img width="200px" src="/images/posts/2018-03-18/nifi_ui_policies.png" /></td>
  </tr>
  <tr>
    <td>Select "proxy user requests" from the policy dropdown and client "Create" a new policy</td>
    <td style="text-align:center"><img width="700px" src="/images/posts/2018-03-18/nifi_ui_policy_proxy_user_create.png" /></td>
  </tr>
  <tr>
    <td>Ensure that "proxy user requests" is selected and click the "Add User" icon</td>
    <td style="text-align:center"><img width="700px" src="/images/posts/2018-03-18/nifi_ui_policy_proxy_user_add.png" /></td>
  </tr>
  <tr>
    <td>Add the user `CN=KNOX_FQDN_HOSTNAME, OU=NIFI` and click "Add"</td>
    <td style="text-align:center"><img width="200px" src="/images/posts/2018-03-18/nifi_ui_policy_proxy_user_add_KNOX_FQDN_HOSTNAME.png" /></td>
  </tr>
  <tr>
    <td colspan="2">Close the "Access Policies" dialog with the "X" button.</td>
  </tr>
</table>

**Add `admin` user to Apache NiFi for use with Apache Knox** 
<table>
  <tr>
    <td>Open the Apache NiFi hamburger menu</td>
    <td style="text-align:center"><img width="200px" src="/images/posts/2018-03-18/nifi_ui_hamburger.png" /></td>
  </tr>
  <tr>
    <td>Click "Users"</td>
    <td style="text-align:center"><img width="200px" src="/images/posts/2018-03-18/nifi_ui_users.png" /></td>
  </tr>
  <tr>
    <td>Click the "Add User" icon</td>
    <td style="text-align:center"><img width="700px" src="/images/posts/2018-03-18/nifi_ui_users_add.png" /></td>
  </tr>
  <tr>
    <td>Enter `admin` into the "Identity" box and click "OK"</td>
    <td style="text-align:center"><img width="200px" src="/images/posts/2018-03-18/nifi_ui_user_add_admin.png" /></td>
  </tr>
  <tr>
    <td colspan="2">Close the "NiFi Users" dialog with the "X" button.</td>
  </tr>
</table>

**Add Apache NiFi policy to allow `admin` user to view user interface**
<table>
  <tr>
    <td>Open the Apache NiFi hamburger menu</td>
    <td style="text-align:center"><img width="200px" src="/images/posts/2018-03-18/nifi_ui_hamburger.png" /></td>
  </tr>
  <tr>
    <td>Click "Policies"</td>
    <td style="text-align:center"><img width="200px" src="/images/posts/2018-03-18/nifi_ui_policies.png" /></td>
  </tr>
  <tr>
    <td>Ensure that "view user interface" is selected and click the "Add User" icon</td>
    <td style="text-align:center"><img width="700px" src="/images/posts/2018-03-18/nifi_ui_policy_view_interface_add.png" /></td>
  </tr>
  <tr>
    <td>Add the user `admin` and click "Add"</td>
    <td style="text-align:center"><img width="200px" src="/images/posts/2018-03-18/nifi_ui_policy_view_interface_add_admin.png" /></td>
  </tr>
  <tr>
    <td colspan="2">Close the "Access Policies" dialog with the "X" button.</td>
  </tr>
</table>

### Setting up Apache Knox
#### Download and Extract Apache Knox
[Download Apache Knox 1.0.0](http://www.apache.org/dyn/closer.cgi/knox/1.0.0/knox-1.0.0.zip) and extract the `.zip` file
```bash
unzip knox-1.0.0.zip
cd knox-1.0.0
```

#### Start Apache Knox Demo LDAP server
```bash
./bin/ldap.sh start
```

#### Start Apache Knox
```bash
./bin/knoxcli.sh create-master 
./bin/gateway.sh start
```

**Note:** Keep track of the Apache Knox master secret since you will need it later.

#### Check Apache Knox
Open Apache Knox in your browser
* `https://KNOX_HOST:8443/gateway/manager/admin-ui/index.html`
    * `KNOX_HOST` - This should be the fully qualified domain name of the `KNOX_HOST`
    * Username = `admin`
    * Password = `admin-password`

You should see this:

<p style="text-align:center"><img width="600px" src="/images/posts/2018-03-18/knox_manager_example.png" /></p>

#### Setup Apache Knox for Apache NiFi
**Add 2-way NiFi TLS/SSL Certificates to Apache Knox**

Make sure to enter the `KNOX_MASTER_SECRET` value that you used from above.

```bash
KNOX_MASTER_SECRET=
keytool -importkeystore -destkeypass $KNOX_MASTER_SECRET -srckeystore /opt/certs/knox/keystore.jks -destkeystore data/security/keystores/gateway.jks -deststoretype JKS -srcstorepass keystore -deststorepass $KNOX_MASTER_SECRET -noprompt
keytool -importkeystore -srckeystore /opt/certs/knox/truststore.jks -destkeystore data/security/keystores/gateway.jks -deststoretype JKS -srcstorepass truststore -deststorepass $KNOX_MASTER_SECRET -noprompt

# Restart Apache Knox to pickup new certificates
./bin/gateway.sh stop
./bin/gateway.sh start
```

**Note:** If you let the Apache NiFi TLS Toolkit generate random passwords then they should be specified here instead. If you chose a different location than /opt/certs put that here as well.

**Add Apache NiFi to Apache Knox sandbox topology**

Add the following to `conf/topologies/sandbox.xml` at the end before `</topology>`. Replace `NIFI_FQDN_HOSTNAME` with the proper value for your Apache NiFi host.
```xml
<service>
  <role>NIFI</role>
  <url>https://NIFI_FQDN_HOSTNAME:9091/</url>
  <param name="useTwoWaySsl" value="true" />
</service>
```

### Check Apache Knox proxying of Apache NiFi 
* `https://KNOX_HOST:8443/gateway/sandbox/nifi-app/nifi`
    * `KNOX_HOST` - This should be the fully qualified domain name of the `KNOX_HOST`
    * Username = `admin`
    * Password = `admin-password`

You should see this:

<p style="text-align:center"><img width="800px" src="/images/posts/2018-03-18/knox_nifi_ui.png" /></p>

## Conclusion
By now you should have a working [Apache Knox](https://knox.apache.org/) proxying [Apache NiFi](https://nifi.apache.org/) setup. As configured, the `admin` user only has permissons to view the Apache NiFi interface. You would need to add more policies for the `admin` user to do more. Apache Knox also has `guest`, `sam`, and `tom` users that you can use to see how different users get passed to Apache Knox. As far as next steps, configuring the [Apache NiFi LDAP authorizer](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#ldap_login_identity_provider) to point to Apache Knox LDAP server could be useful for simplifying permissions.

If you are using [Hortonworks Data Flow (HDF)](https://hortonworks.com/products/data-platforms/hdf/) and [Hortonworks Data Platform (HDP)](https://hortonworks.com/products/data-platforms/hdp/), [Apache Ambari](https://ambari.apache.org) manages many of the settings laid out above. You can check the file values against what is recommended here, but you need to use Ambari to configure the different settings.

If you have further questions not answered here, reach out on the [Apache Knox user mailing list](https://knox.apache.org/mail-lists.html). 

## Troubleshooting Apache Knox and Apache NiFi
The troubleshooting steps below are designed to answer questions about Apache Knox and Apache NiFi based on the configurations above. For the most part, they are generic enough for any TLS/SSL debugging and can hopefully point you in the right direction.

### Apache NiFi Logs
Apache NiFi logs are located in the `logs` directory where you extracted the `tar.gz` file. `nifi-app.log` will have Apache NiFi application logs. `nifi-user.log` will have Apache NiFi user related logs. Most errors due to misconfigured TLS/SSL will be in `nifi-app.log`.

### Apache Knox Logs
Apache Knox logs are located in the `logs` directory where you extracted the `.zip` file. `gateway.log` will have most of the TLS/SSL related errors. Note that by default Apache Knox only logs `ERROR` messages and will not show more details. If you want more details, in `conf/gateway-log4j.properties` change `log4j.rootLogger=ERROR, drfa` to `log4j.rootLogger=INFO, drfa`.

### Browser - "Your connection is not private"
```
Your connection is not private
Attackers might be trying to steal your information from HOSTNAME (for example, passwords, messages, or credit cards).
```

Your browser does not trust the Apache NiFi TLS Toolkit CA. Typically you can safely ignore this warning. To fix the warning, you need to have your browser turst the Apache NiFi TLS Toolkit CA certificate.

### Browser - "This site can't provide a secure connection"
```
This site can’t provide a secure connection
```

The error typically happens when you are trying to connect to an endpoint that doesn't support SSL/TLS. Note that this message will NOT say "login certificate". If the message says "login certificate" see the error below. For this error, see details above in "Configure Apache NiFi for TLS/SSL".

### Browser - "This site can't provide a secure connection" - "login certificate"
```
This site can’t provide a secure connection
HOSTNAME didn’t accept your login certificate, or one may not have been provided.
```

The error typically happens when you have a service like Apache NiFi that requires 2 way SSL and the browser doesn't have a client certificate. See details above in "Configure Browser for Apache NiFi TLS/SSL Authentication".

Another reason for this could be that Apache NiFi doesn't trust the client certificate provided. The Apache NiFi truststore configured in `nifi.properties` could not trust the certificate provided. There aren't any errors in `nifi-app.log` that would indicate this. See details above in "Configure Apache NiFi for TLS/SSL".

### Apache NiFi - Fails to start - `... no truststore properties are configured.`
```
Caused by: org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'flowService': FactoryBean threw exception on object creation; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'flowController': FactoryBean threw exception on object creation; nested exception is org.apache.nifi.framework.security.util.SslContextCreationException: Need client auth is set to 'true', but no truststore properties are configured.
```

This happens if the truststore is not configured in `nifi.properties`. See details above in "Configure Apache NiFi for TLS/SSL".

### Apache NiFi - Fails to start - `Keystore was tampered with, or password was incorrect`
```
2018-03-17 12:58:13,580 WARN [main] org.apache.nifi.web.server.JettyServer Failed to start web server... shutting down.
java.io.IOException: Keystore was tampered with, or password was incorrect
```

This error occurs when there is a bad password in `nifi.properties` for the truststore or keystore. See details above in "Configure Apache NiFi for TLS/SSL".

### Apache NiFi - Unknown user with identity - `CN=nifi-admin, OU=NIFI`
```
Unknown user with identity 'CN=nifi-admin, OU=NIFI'. Contact the system administrator.
```

Most likely means there is a typo in `conf/authorizers.xml`. The space between ", OU=" is very important. See details above in "Configure Apache NiFi for TLS/SSL".

### Apache NiFi - Insufficient Permissions - Untrusted proxy
```
Insufficient Permissions
Untrusted proxy CN=KNOX_FQDN_HOSTNAME, OU=NIFI
```

This is caused by Apache NiFi not having a user or a policy to allow Apache Knox to act as a trusted proxy. See details above in "Configure Apache NiFi for Apache Knox".

### Apache NiFi - Unknown user with identity - `CN=admin, OU=NIFI`
```
Unknown user with identity 'CN=admin, OU=NIFI'. Contact the system administrator.
```

Most likely means that the `admin` user was not setup in Apache NiFi. See details above in "Add admin user to Apache NiFi for use with Apache Knox".

### Apache NiFi - Insufficient Permissions - Unable to view the user interface
```
Insufficient Permissions
Unable to view the user interface. Contact the system administrator.
```

Most likely means you missed adding the `admin` user to the `view user interface` Apache NiFi policy. See details above in "Add Apache NiFi policy to allow admin user to view user interface".

### Apache Knox - Browser - Repeated login boxes
This means that you either have entered the wrong username/password or that the Apache Knox LDAP server is not started. See details above in "Start Apache Knox Demo LDAP server".

### Apache Knox - Fails to start - `UnrecoverableKeyException: Cannot recover key`
```
2018-03-17 12:49:02,873 FATAL knox.gateway (GatewayServer.java:main(163)) - Failed to start gateway: java.security.UnrecoverableKeyException: Cannot recover key
```

This is caused when there is an alias in `gateway.jks` that doesn't have the `keypassword` set to the Apache Knox master secret. This happens when you import a certificate from a keystore like `KNOX_FQDN_HOSTNAME/keystore.jks` and don't set the `-destkeypass` to the Apache Knox master secret. See details above in "Add 2-way NiFi TLS/SSL Certificates to Apache Knox".

### Apache Knox - Browser - 500 Error
```
HTTP ERROR 500
Problem accessing /gateway/sandbox/nifi-app/nifi. Reason:
Server Error
```

This error can manifest itself in a variety of ways with Apache Knox. You need to look at the Apache Knox logs at `logs/gateway.log` and look for the specific error. Some errors are below:

#### Apache Knox - host not reachable?
```
2018-03-17 12:53:39,558 WARN  knox.gateway (DefaultDispatch.java:executeOutboundRequest(147)) - Connection exception dispatching request: https://nifi/?user.name=admin java.net.UnknownHostException: nifi: nodename nor servname provided, or not known
java.net.UnknownHostException: nifi: nodename nor servname provided, or not known
```

This error happens when you have the wrong `<url></url>` set in Apache Knox topology xml file for the Apache NiFi service. See details above in "Add Apache NiFi to Apache Knox sandbox topology".

#### Apache Knox - `PKIX path building failed`
```
2018-03-17 12:35:46,420 WARN  knox.gateway (DefaultDispatch.java:executeOutboundRequest(147)) - Connection exception dispatching request: https://NIFI_FQDN_HOSTNAME:9091/nifi?user.name=admin javax.net.ssl.SSLHandshakeException: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
javax.net.ssl.SSLHandshakeException: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
```

The errors "PKIX path building failed" and "unable to find valid certification path" happen when Apache Knox doesn't trust the certificate of Apache NiFi. Most likely the `truststore.jks` certificates generated for Apache Knox by the Apache NiFi TLS Toolkit were not imported into `gateway.jks`. See details above in "Add 2-way NiFi TLS/SSL Certificates to Apache Knox".

The second reason this can happen is if `<param name="useTwoWaySsl" value="true" />` is missing in Apache Knox topology xml file for the Apache NiFi service. To check and fix this, see details above in "Add Apache NiFi to Apache Knox sandbox topology".

#### Apache Knox - `Received fatal alert: bad_certificate`
```
2018-03-17 12:41:39,413 WARN  knox.gateway (DefaultDispatch.java:executeOutboundRequest(147)) - Connection exception dispatching request: https://NIFI_FQDN_HOSTNAME:9091/nifi?user.name=admin javax.net.ssl.SSLHandshakeException: Received fatal alert: bad_certificate
javax.net.ssl.SSLHandshakeException: Received fatal alert: bad_certificate
```

This is most likely caused by the Apache NiFi TLS Toolkit Apache Knox keystore not being imported into `gateway.jks`. To check and fix this, see details above in "Add 2-way NiFi TLS/SSL Certificates to Apache Knox".

Another reason for this could be that Apache NiFi doesn't trust the client certificate provided. The Apache NiFi truststore configured in `nifi.properties` could not trust the certificate provided. There aren't any errors in `nifi-app.log` that would indicate this. See details above in "Configure Apache NiFi for TLS/SSL".

#### Apache Knox - `SSLPeerUnverifiedException`
```
javax.net.ssl.SSLPeerUnverifiedException: Certificate for <NIFI-IP-ADDR> doesn't match any of the subject alternative names: [NIFI-IP-ADDR]
```

In the blog above I don't recommend using IP addresses since they don't work well with TLS/SSL certificates. The Apache NiFi TLS Toolkit [does not support generating certificates for IP addresses](https://github.com/apache/nifi/blob/master/nifi-toolkit/nifi-toolkit-tls/src/main/java/org/apache/nifi/toolkit/tls/util/TlsHelper.java#L226). The error above is because the certificate thinks the IP address is actually a DNS entry and doesn't match.

### Something not mentioned?
If you have further questions not answered here, reach out on the [Apache Knox user mailing list](https://knox.apache.org/mail-lists.html). 

