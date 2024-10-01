---
layout: post
title:  "How does memory allocation work in libvirt?"
date:   2024-05-05 19:00:00 +0100
categories: os, virtualization
tags: libvirtd, memory
---

TODO

  <memory unit='KiB'>8388608</memory>
  <currentMemory unit='KiB'>8388608</currentMemory>



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

maxMemory is how much more memory can be hotplugged to the kvm. This value can be the same as memory or more.
e.g. If the memory is 8GiB and then maxMemory is 16GiB we can hod-plug another 8GiB to the kvm.

What causes the hypervisor not to give the spare memory to the guest?
OS, cgroups? The hypervisor has more then 40GB free of RAM so there is not other requirement.

How does the OS manages memory and how can we request more memory than the currentAllocation?
stress-ng and malloc does not seem to do this? Is there another setting?
We have disabled swappiness completely in the guest.



https://lxr.linux.no/#linux+v2.6.34.1/drivers/virtio/virtio_balloon.c
https://rwmj.wordpress.com/2010/07/17/virtio-balloon/
https://pmhahn.github.io/virtio-balloon/

Seems the balloning is manual process...

https://www.linux-kvm.org/page/Projects/auto-ballooning



See below. If we set the autodeflate attribute to 'on' then the kvm reports the size of the memory element
not the currentMemory and the size of the currentMemory is hogged by the baloon driver.
If we request more than 4gb the ballon driver space is reclaimed by the kvm. 
https://libvirt.org/formatdomain.html#memory-balloon-device

watch -n 1 virsh -c qemu:///system dommemstat fedora39_memaloc

stress --vm 4 --vm-keep --vm-bytes 1024M

We need to test how the host can ask the memory back... stress test the hypervisor???

The hypervisor stress process was killed by the oom-killer regardless if the kvm was requesting the memory.
The RES mem of the qemu-kvm process was not decreased after stopping the stress test in the kvm.

By adding the attribute freePageReporting="on" in the memballoon element of the kvm the RES mem is reduced gradually
after terminating the stress test in the hypervisor.

NB. The used memory though in the KVM does not become the remainder of Max-Current but stays low.
If we set the currentMemory element using virsh then the baloon driver inflates and you can see that it hogs 
the rest of the memory.

The [Standard C Library](https://www.gnu.org/software/libc/libc.html){:target="_blank"} has a header file [netdb.h](https://github.com/bminor/glibc/blob/master/resolv/netdb.h){:target="_blank"} with definitions for network database operations. This is part of the [resolver library](https://tldp.org/LDP/nag2/x-087-2-resolv.library.html){:target="_blank"} which includes the following two methods.

* gethostbyname()
* gethostbyaddr()

Thank you,

Petros


<div id="commentics"></div>
