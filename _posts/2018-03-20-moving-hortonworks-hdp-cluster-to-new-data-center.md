---
title: Moving Hortonworks HDP Clusters to a New Data Center
date: 2018-03-20 13:00:00 -05:00
tags:
- bigdata
- hortonworks
- hdp
- hadoop
- moving
- data center
layout: post
---

### Overview
My team supports multiple [Hortonworks Data Platform (HDP)](https://hortonworks.com/products/data-platforms/hdp/) clusters and has for a number of years. About a year ago, we embarked on a journey to add multi data center capabilities for our platform. Our platform has been expanding over the last few years and we needed to purchase more hardware. We decided to keep the new hardware in our regular data center and move the older hardware to a new data center. This was an interesting challenge and one that we were able to succeed at.

### Move Requirements
The HDP clusters are secured with TLS/SSL, LDAP, and Kerberos. There are a few other security related configurations as well. We did not disable or change any security related configuration for this move. The clusters were left configured as is and then moved to the new data center. 

### The Move
In early 2017, it was decided by leadership that we were going to support multiple data centers. The goal was to have everything ready by October 2017 with improvements continuing after that. Our new hardware was set to arrive in April and needed to be ready for use by mid May. While my team worked to setup and configure the new hardware, we worked to figure out logistics of moving a cluster from one data center to another.

The older hardware was split into 4 clusters and we wanted to not only move them but recombine them into 2 larger clusters. We planned that we could move all use cases to the new hardware and then focus on rebuilding the older hardware clusters. Rebuilding the older hardware clusters took 4-6 weeks since our vendor needed to reconfigure the system as well. By August, the older hardware clusters had been reconfigured. Since the clusters were designed for disaster recovery and potentially high availability, we performed a final data sync before the clusters were disconnected from the network to ship. Our network and data center team did a fantastic job of making sure all the necessary arrangements were made. This included disconnecting switches and other steps. We hired a shipping company to relocate the hardware from one data center to another. 

While the old clusters were being rebuilt, the other data center team was working on preparing for the cluster arrivals. This included setting up power, network, and floor space. Network drops were setup ahead of time and the switches were preconfigured to ensure they could be enabled quickly. With all the preparations complete, we waited the few days for the clusters to arrive at the new data center.

### Standing the Clusters Up at the New Data Center
The clusters arrived intact at the new data center and needed to acclimate after the trip. We were against a tight deadline due to a large company wide software rollout happening at the same time which restricted allowed changes. Once the clusters had acclimated, our vendor and data center teams went to work to reconnect the clusters. The teams did a fantastic job ensuring that every single network cable was connected successfully the first time. We had a few minor hardware problems that needed to be addressed after the move but it was a very succcessful reconnection. The move required changing IP addresses for the entire cluster which also went without a hitch. During the move, we reassigned the hostname allocations from the old data center IP address block to the new data center one.

The moment of truth was after the clusters were reconnected to the network and machines were powered on. We opened up [Apache Ambari](https://ambari.apache.org/) and hit the "Start All" button to see if HDP would come back up. To my surprise, the entire cluster came back up with no issues. We didn't miss a single step during the move and everything went smootly. 

### Lessons Learned and Things That Went Well
* Pick shipping company sooner
    * Shipping the cluster was harder than we expected
* Provide the networking team plenty of time to get the network setup
* Provide the data center team plenty of time to get ready
* **DO NOT** change the cluster hostnames
    * We did not change the hostnames on purpose since that would have broken the security model and required extensive amount of work to rebuild.
* A lot of hardwork and a little bit of luck goes a long way
    * The teams involved with the move all did a fantastic job of keeping to the schedule
    * To not have a single missed step during the entire move was impressive to see

### Conclusion
We successfully moved two HDP clusters from one data center to another without any issues. We didn't disable or compromise on any security during the move either. The entire process took approximately 6 months from end to end including the up front planning. In the end, we were successful in moving the clusters ahead of the aggressive deadlines.

