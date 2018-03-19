---
title: Apache Storm - Topology Permissions
date: 2018-03-28 09:00:00 -05:00
tags:
- bigdata
- apache
- storm
- topology
- permissions
- security
- stability
layout: post
---

### Overview
[Apache Storm](https://storm.apache.org/) is a distributed system designed for processing streams of information. Each unit of processing is called a bolt and a group of bolts with an initial spout is called a topology. Multiple topologies can be deployed on a single Apache Storm cluster. Multi tenancy within an Apache Storm cluster requires the ability to prevent any user from killing a topology or viewing the topology logs. Much of the information comes from the [Apache Storm security documentation](http://storm.apache.org/releases/current/SECURITY.html) but it isn't entirely clear what each setting does.

### Apache Storm Topology Permissions
By default when security is enabled for Apache Storm, only the user who deploys the topology has access to admin operations such as rebalance, activate, deactivate, and kill. The configurations below can be set at the cluster or topology level. If they are defined in the topology they will override the global configuration.

| Configuration | Description |
| ------------- | ----------- |
| `topology.users` / `topplogy.groups` | This allows the users/groups specified to act as owners of the topology. This allows users to perform topology admin operations such as rebalance, activate, deactivate, and kill. |
| `logs.users` / `logs.groups` | This allows the users/groups specified to look at the logs of the topology. |

### Apache Storm Cluster Admin Permissions
There is one cluster level configuration that will enable a set of users to be admins for the entire Apache Storm cluster.

| Configuration | Description |
| ------------- | ----------- |
| `nimbus.admins` | These users will have super user permissions on all topologies deployed. They will be able to perform other admin operations (such as rebalance, activate, deactivate and kill), even if they are not the owners of the topology. |

