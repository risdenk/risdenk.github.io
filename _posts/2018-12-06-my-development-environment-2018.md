---
title: My Development Environment 2018
date: 2018-12-06 08:00:00 -06:00
tags:
- development
- environment
- 2018
layout: post
---

### Overview
I was asked the other day about what my development environment looked like since I was able to test a lot of different configurations quickly. I am writing this post to capture some of the stuff I do to be able to iterate quickly. First some background on why it has historically been important for me to be able to change test environments quickly.

#### Background
I previously worked as a software consultant with [Avalon Consulting, LLC](https://www.avalonconsult.com/). We worked on a variety of projects for a number of different clients. Some of the projects were long and others were shorter. I focused primarily on big data and search. [Apache Hadoop](https://hadoop.apache.org/) with security has a lot of different configurations. It wasn't practical to spin up cloud environments (hotel wifi sucks) for each little test. This meant I needed to find a way to test things on my 8GB Macbook Pro.

### Development Laptop
I currently have 2 laptops for development. A 2012 8GB RAM Macbook Pro that is starting to show its age, but was worth every penny. A second work laptop that I won't go into too much detail. Both laptops are configured very similarly. Key software includes:

* [iTerm2](https://www.iterm2.com/)
* [Homebrew](https://brew.sh/)
* [Zsh](http://www.zsh.org/)
* [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
* [git](https://git-scm.com/)
* [Docker for Mac](https://docs.docker.com/docker-for-mac/)
* [VirtualBox](https://www.virtualbox.org/)
* [Vagrant](https://www.vagrantup.com/)
* [IntelliJ IDEA Ultimate](https://www.jetbrains.com/idea/)
* [Chrome](https://www.google.com/chrome/)

I use my terminal quite a bit. I use it for git, ssh, docker, vagrant, etc. I typically leave my terminal up at all times since I am usually running something. I jump between Docker and Vagrant/Virtualbox quite a bit. There are lots of security and distributed computing setups where proper hostnames and DNS resolution works better with full virtual machines. There are fewer gotchas if you know you are working with "real" machines instead of fighting with Docker networking and DNS.

I owe a big shoutout to [Travis CI](https://travis-ci.com/) since I use them a lot for my open source projects. I typically push a git branch to my Github fork and let Travis CI go to work. This allows me to work on multiple things at once when tests take 10s of minutes.

### Intel NUC Server
I recently added an [Intel NUC](https://simplynuc.com/8i5beh-kit/) to my development setup to help with offloading some of the long running tests from my laptop. It also has more RAM and CPU power that allows me to run continuous integration jobs as well as more Vagrant VMs. Some of the software I have running on my Intel NUC (mostly as Docker containers):

* [Dnsmasq](https://en.wikipedia.org/wiki/Dnsmasq)
* [Jenkins](https://jenkins.io/)
* [Nexus 3](https://www.sonatype.com/download-oss-sonatype)
* [Gogs](https://gogs.io/)
* [Sonarqube](https://www.sonarqube.org/)

Dnsmasq ensures that I can get a consistent DNS both on my Intel NUC and within my private network. Jenkins runs most of my continuous integration builds. It helps keep track of logs and allows me to spin up jobs for different purposes (like repeatedly testing a feature branch). Jenkins spins up separate Docker containers for each build so I don't have to worry about dependency conflicts. Nexus allows me to cache Maven repositories, Docker images, static files, and more. This ensures that I don't need to wait to redownload the same dependencies over and over again. Gogs is a standalone Git server that painlessly lets me mirror repos internally. This avoids me having to pull big repos from the internet over and over again. Sonarqube enables me to run some additional static build checks against some of the Jenkins builds.

### Yubikey
I want to talk a little bit about my use of a Yubikey. I had been thinking about getting one for a few years and finally got one when Yubikey 5 came out. I use it all the time now for GPG and SSH. I am able to not store any private keys on my new devices and can even SSH from a Chromebook back to my server if necessary. I configured my Yubikey to handle both GPG for signing and authentication. This allows me to use GPG with SSH as well. The GPG agent takes a little configuring, but once setup you can easily use it for both GPG and SSH. I wish more websites supported U2F instead of OATH/Authenticator codes. I like the simplicity and would recommend it for most developers.

### Conclusion
My setup hasn't changed too much over the past 5 years when it comes to development laptops. I have started to use more cloud based automated testing like Travis CI. I added the Intel NUC to be able to do more testing internally across bigger VMs. I will say that I have learned more trying to fit a distributed system on an 8GB RAM laptop than anything else. (Who else can say they have run Hadoop on 3 Linux VMs and 1 Windows AD VM on 8GB of RAM). Who knows what is to come in 2019, but I am happy and productive with what I have in 2018.

