---
layout: post
title:  "How does memory allocation work in libvirt?"
date:   2024-05-05 19:00:00 +0100
categories: os, virtualization
tags: libvirtd, memory
---

TODO



```
code listing
```

we need to define the KVM in libvirt
start with 2GB mem and current memory

define --file /home/ppetrou/Dev/libvirtd-blog-artefacts/memalloc/kvm.xml


View the mem stats

dominfo --domain fedora39_memaloc 
dommemstat --domain fedora39_memaloc

Check what the os reports 

[root@fedora39-base ~]# swapon -s
[root@fedora39-base ~]# cat /proc/swaps 
Filename                                Type            Size            Used            Priority
[root@fedora39-base ~]# 
[root@fedora39-base ~]# 


https://askubuntu.com/questions/1188024/how-to-test-oom-killer-from-command-line/1188063#1188063





The [Standard C Library](https://www.gnu.org/software/libc/libc.html){:target="_blank"} has a header file [netdb.h](https://github.com/bminor/glibc/blob/master/resolv/netdb.h){:target="_blank"} with definitions for network database operations. This is part of the [resolver library](https://tldp.org/LDP/nag2/x-087-2-resolv.library.html){:target="_blank"} which includes the following two methods.

* gethostbyname()
* gethostbyaddr()

Thank you,

Petros


<div id="commentics"></div>
