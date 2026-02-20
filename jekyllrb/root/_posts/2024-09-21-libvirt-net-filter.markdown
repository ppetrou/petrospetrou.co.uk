---
layout: post
title:  "Network outage simulation in libvirt using netfilter"
date:   2024-09-23 22:00:00 +0100
categories: virtualization
tags: libvirtd, network, netfilter
---

As I tend to work in cluster configuration and administration one of the most tricky tasks is how to
test network outage in a virtualized environment.

One solution is to disable the network interface or set firewall rules but this is more of a hack
as we are configuring this in the OS. A better approach is to use the 
libvirt [netfilter](https://libvirt.org/formatnwfilter.html){:target="_blank"} which is configured at the
hypervisor.

As an example I will block unicast traffic between two KVMs using the sender MAC address.

I will define my filter in an XML file and name it block_unicast_traffic.xml

```
<filter name='block-unicast-traffic' chain='ipv4'>
  <rule action='drop' direction='inout'>
      <ip protocol='udp' srcmacaddr='$SENDER_MAC' />
  </rule>
</filter>
```

The filter will use the ipv4 protocol-specific filtering chain and we will use a simple
rule to drop packages that originate from a specific MAC address. We are defining the MAC address
by using the custom $SENDER_MAC parameter. 

The next step is to create the netfilter in libvirt using virsh and nwfilter-define.

```
virsh # nwfilter-define --file /home/ppetrou/Dev/libvirt_netfilter_samples/block_unicast_traffic.xml
Network filter block-unicast-traffic defined from /home/ppetrou/Dev/libvirt_netfilter_samples/block_unicast_traffic.xml
```

Next step is to create a netfilter binding as we need to bind the filter with a network interface of a KVM.
We could do this just by adding a filterref element in the domain XML in the interface element but this would make
things complex if we wanted to add/remove the filter on the fly without having to reboot the KVM.

```
<devices>
  <interface type='bridge'>
    <mac address='00:16:3e:5d:c7:9e'/>
    <filterref filter='clean-traffic'/>
  </interface>
</devices>
```

The filter binding can be added and removed from a KVM when the KVM is powered on so this can ease our testing
on when connectivity is lost or resumed.

In the owner element we MUST define the KVM name and its UUID. You can get this from the domain XML of the KVM.
The portdev element is mandatory and defines the virtual network port name of the interface we want to bind the filter.
The mac element is the mac address of the interface we want to bind the filter.

The most important part is the filterref element were we define the filter and also initialize any parameters.
In this case we need to initialize the $SENDER_MAC parameter with the MAC address of the sender. 


```
<filterbinding>
  <owner>
    <name>vm1</name>
    <uuid>80d59483-aec0-4d9f-b5f0-55f39ad1871e</uuid>
  </owner>
  <portdev name='vnet1'/>
  <mac address='52:54:00:83:73:8a'/>
  <filterref filter='block-unicast-traffic'>
    <parameter name='SENDER_MAC' value='52:54:00:fc:ee:d4'/>
  </filterref>
</filterbinding>
```

In order to test this we will use two KVMs.
The network interface which we will use is the enp7s0 and has the portdev name vnet1. 


```
[root@node1 ~]# 
[root@node1 ~]# nmcli con show
NAME                UUID                                  TYPE      DEVICE 
enp1s0              8660f145-f5c6-46c1-995f-33460a027c47  ethernet  enp1s0 
Wired connection 1  51fdfc6c-df5e-35f3-a7bb-c11bf2c18676  ethernet  enp7s0 
Wired connection 2  abf63925-a804-391c-859a-498f6d1bb4fe  ethernet  enp8s0 
[root@node1 ~]# 
[root@node1 ~]# ip a show enp7s0
3: enp7s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:83:73:8a brd ff:ff:ff:ff:ff:ff
    inet 192.168.100.182/24 brd 192.168.100.255 scope global dynamic noprefixroute enp7s0
       valid_lft 2560sec preferred_lft 2560sec
    inet6 fe80::88ca:707f:1bc3:d496/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
[root@node1 ~]# 
[root@node1 ~]# 

[root@node2 ~]# nmcli con show
NAME                UUID                                  TYPE      DEVICE 
enp1s0              8660f145-f5c6-46c1-995f-33460a027c47  ethernet  enp1s0 
Wired connection 1  9500b4e5-f052-32b0-8cd4-0557250f55b0  ethernet  enp7s0 
Wired connection 2  50ed8da0-0cf7-34f1-a5d4-46b17d3f593c  ethernet  enp8s0 
[root@node2 ~]# 
[root@node2 ~]# ip a show enp7s0
3: enp7s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:fc:ee:d4 brd ff:ff:ff:ff:ff:ff
    inet 192.168.100.201/24 brd 192.168.100.255 scope global dynamic noprefixroute enp7s0
       valid_lft 2479sec preferred_lft 2479sec
    inet6 fe80::daae:eb36:f3c3:d2e8/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
[root@node2 ~]# 
[root@node2 ~]# 
```

First we wil test that connectivity is OK.

```
[root@node2 ~]# nc -vu 192.168.100.182 2233
Ncat: Version 7.92 ( https://nmap.org/ncat )
Ncat: Connected to 192.168.100.182:2233.
test


[root@node1 ~]# nc -lvu 192.168.100.182 2233
Ncat: Version 7.92 ( https://nmap.org/ncat )
Ncat: Listening on 192.168.100.182:2233
Ncat: Connection from 192.168.100.201.
test
```

and then we will apply the netfilter binding and re-test to check that connectivity is lost

```
virsh # nwfilter-binding-create --file /home/ppetrou/Dev/libvirt_netfilter_samples/block_unicast_binding_vm1.xml 
Network filter binding on vnet1 created from /home/ppetrou/Dev/libvirt_netfilter_samples/block_unicast_binding_vm1.xml

[root@node2 ~]# nc -vu 192.168.100.182 2233
Ncat: Version 7.92 ( https://nmap.org/ncat )
Ncat: Connected to 192.168.100.182:2233.
test
test2 <-- this message never arrives to node1
test3 <-- same this one
test4 <-- same this one

[root@node1 ~]# nc -lvu 192.168.100.182 2233
Ncat: Version 7.92 ( https://nmap.org/ncat )
Ncat: Listening on 192.168.100.182:2233
Ncat: Connection from 192.168.100.201.
test
     <-- no new messages
```

Now we will remove the netfilter binding

```
virsh # nwfilter-binding-list 
 Port Dev   Filter
-----------------------------------
 vnet1      block-unicast-traffic

virsh # 
virsh # nwfilter-binding-delete --binding vnet1 
Network filter binding on vnet1 deleted

[root@node2 ~]# nc -vu 192.168.100.182 2233
Ncat: Version 7.92 ( https://nmap.org/ncat )
Ncat: Connected to 192.168.100.182:2233.
test
test2
test3
test4
test5 <-- newer message is received in node1

[root@node1 ~]# nc -lvu 192.168.100.182 2233
Ncat: Version 7.92 ( https://nmap.org/ncat )
Ncat: Listening on 192.168.100.182:2233
Ncat: Connection from 192.168.100.201.
test
test5 <-- newer message
```

You can find the XML artefacts in my [GitHub](https://github.com/ppetrou/libvirt_netfilter_samples){:target="_blank"}.

That's it. I hope you found this blog useful. 

Thank you,

Petros


