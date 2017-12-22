---
title: "%2F with WebHBase, Apache Knox, and Traefik - Part 2"
date: 2017-12-22 12:00:00 -06:00
tags:
- bigdata
- "%2f"
- apache
- knox
- traefik
layout: post
---

### Background
See [part 1]({% post_url 2017-12-21-percent-2f-webhbase-knox-traefik-part-1 %}) for background on the "`%2F` problem" with [WebHBase](https://hbase.apache.org/book.html#_rest), [Apache Knox](https://knox.apache.org/), and [Traefik](https://traefik.io/).

### Traefik and `%2F`
After fixing `%2F` with Apache Knox, the group attempted to move to the load balancer URL instead of directly pointing to a single Apache Knox server. When doing so, they found out that the "`%2F` problem" bit them again.

#### Debugging Traefik for `%2F`
In order to handle easy transitions between environments, we opted to have a single DNS hostname with URL paths to determine backends. The URL rewriting in Traefik was taking the `%2F` and converting it into a `/`. This caused the same symptoms as with Apache Knox dispatching the wrong URL when `%2F` was included.

Debugging Traefik (written in Go) was not as simple as Apache Knox (written in Java) because we had prior experience with Java. It would also be risky to change Traefik's internal URL encoding since it could break typical use cases. For the time being, it was decided that the group would stay pointed to a single Apache Knox server and risk outages if that node failed.

After a few months and no progress being made fixing Traefik, I stumbled upon [Traefik 1.4.4](https://github.com/containous/traefik/releases/tag/v1.4.4). Traefik 1.4.4 included a fix for URL encoding characters to backend servers. [Traefik pull request #2382](https://github.com/containous/traefik/pull/2382) used an example of `%2F` showing how it could be fixed by setting `RawPath` for URIs in `stripPrefix`. We upgraded to Traefik 1.4.4 and the group tested their application. Sadly this did not fix the "`%2F` problem" for them completely. This however did give hope that we were closer to finding a solution.

#### Fixing Traefik `addPrefix` for `%2F`
Since PR #2382 showed how it was easy to adjust Traefik for handling `%2F` correctly, I focused on understanding what the change involved. I debugged Traefik further and found that we were using `addPrefix` in addition to `stripPrefix`. `addPrefix` had not been fixed even though it suffered from the same poor handling of `%2F`. I opened [pull request #2560](https://github.com/containous/traefik/pull/2560) to fix `addPrefix` building off of PR #2382. The Traefik maintainers quickly evaluated the PR and merged the PR. 

Traefik 1.5.0 will be the first release that should fix the "`%2F problem". With [Traefik 1.5.0 RC3](https://github.com/containous/traefik/releases/tag/v1.5.0-rc3) being released just a few days ago (with PR #2560 included), we are waiting on a GA release of Traefik 1.5.x to go ahead with upgrading. Once we get a chance to upgrade to Traefik 1.5.x, we will have the group test their application again. If successful, that group will move to a support configuration through the load balancer.

### Conclusion
`%2F` is an interesting URL encoding problem since `/` is a valid URI separator. Even though it is possible to store data with `%2F` in the identifier, I don't recommend doing so. There are too many cases where `%2F` can be wrongly interpreted and you will have to chase the problem down your stack one layer at a time. We have prevented other groups from encountering this issues by always forcing them through the load balancer to start. I have also advised against other groups using `%2F` in their ids.

