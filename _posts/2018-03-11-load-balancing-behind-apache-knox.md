---
title: Load Balancing Behind Apache Knox
date: 2018-03-11 12:00:00 -06:00
tags:
- bigdata
- apache
- knox
- load
- balancing
- webhbase
- hbase
- spnego
- kerberos
- security
layout: post
---

Shout out to @westeras who figured out most of the content below in the fall of 2017. 

### Overview
[Apache Knox](https://knox.apache.org/) supports HA in that if one backend server fails, it will begin forwarding requests to the next server in its list. However, Knox will only forward requests to one server at a time. Native load balancing in Knox is being worked on in [KNOX-843](https://issues.apache.org/jira/browse/KNOX-843). In order to perform load balancing today, it necessary to put a load balancer between Knox and backend services (in this case, WebHBase) in order to truly balance the load on the back end. The difficult part is configuring the backend service to accept HTTP Kerberos authentication from a server other than its own.

### Apache Knox and WebHBase
Before the load balancer is inserted, a REST call through Knox to WebHBase goes like this:
1. Client submits call to Knox, targeting WebHBase endpoint (e.g. [https://knox.gateway.host:8443/gateway/default/hbase/version](https://knox.gateway.host:8443/gateway/default/hbase/version)), providing basic auth credentials.
2. Credentials are verified against LDAP, and Knox obtains a Kerberos service ticket to authenticate to the backend service.
    * This service ticket is specific to the host that Knox is connecting to, e.g. HTTP/webhbase.example.com
3. Knox uses the service ticket to authenticate to WebHBase, which fulfills the request and returns to Knox.
4. Knox returns to the client with the response from WebHBase.

Below is a diagram illustraing this process.

<p style="text-align:center"><img width="600" src="/images/posts/2018-03-11/knox_webhbase_flow_diagram.png" /></p>

### Apache Knox, Load Balancer, and WebHBase
Adding a load balancer between Knox and WebHBase introduces some complexity since the load balancer and WebHBase will typically run on different hosts. When Knox obtains a service ticket specific to the load balancer host, authentication against the WebHBase host will fail if configuraiton changes are not made. We need to configure WebHBase to accept authentication from any of the hosts that may connect it (i.e. all the load balancer nodes).

To do this, we have to:
* Merge all load balancer host Kerberos principals and WebHBase host principals into one keytab
* Distribute the keytab to all WebHBase nodes
* Configure WebHBase's service principal with a wildcard to force it to accept any principal within the merged keytab

Here is a diagram showing the flow with the load balancer.

<p style="text-align:center"><img width="800" src="/images/posts/2018-03-11/knox_load_balancer_webhbase_flow_diagram.png" /></p>

The only change in WebHBase configuration required is to set the following property (which forces WebHBase to accept authentication using any principal within the merged keytab rather than a specific one):
```xml
<property>
  <name>hbase.rest.authentication.kerberos.principal</name>
  <value>*</value>
</property>
```

### Load Balancing and Kerberos/SPNEGO Endpoints
The example with WebHBase can be generalized to apply to other Kerberos SPNEGO endpoints. [Apache Oozie](https://oozie.apache.org) is another service that needs special handling when it comes to load balancing. The main keys to remember are:
* merge keytab with all the host's `HTTP/hostname` keytabs
* Configure SPNEGO principal to be `*` instead of a single `HTTP/hostname` principal

