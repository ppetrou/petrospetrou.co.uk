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


1. Increasing the memory pressure in the KVM does not increase the currentMemory value.
The OS reports the original value all the time and the OOM killer kicks in. (htop)

During boot time the currentMemory is set to the value of the maximumAllocation and
gradually decreases to the value set in the domain XML. Keep in mind that maximumAllocation is
the memory element and not the maxMemory element. Not sure what the maxMemory element is all about.

What causes the hypervisor not to give the spare memory to the guest?
OS, cgroups? The hypervisor has more then 40GB free of RAM so there is not other requirement.

How does the OS manages memory and how can we request more memory than the currentAllocation?
stress-ng and malloc does not seem to do this? Is there another setting?
We have disabled swappiness completely in the guest.


The [Standard C Library](https://www.gnu.org/software/libc/libc.html){:target="_blank"} has a header file [netdb.h](https://github.com/bminor/glibc/blob/master/resolv/netdb.h){:target="_blank"} with definitions for network database operations. This is part of the [resolver library](https://tldp.org/LDP/nag2/x-087-2-resolv.library.html){:target="_blank"} which includes the following two methods.

* gethostbyname()
* gethostbyaddr()

Thank you,

Petros


<div id="commentics"></div>
