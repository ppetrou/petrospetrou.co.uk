---
layout: post
title:  "Who does the DNS Lookup? The browser or the operating system?"
date:   2022-10-10 20:00:00 +0100
categories: os
tags: dns, linux, resolver
---

A common interview question for infrastructure roles is "Who does the DNS Lookup? The browser or the Operating System". A few years ago when I had this question from a UK FS Consultancy, my mind started spinning and was doing endless loops on what could be the correct answer. As a passionate programmer I tend to overthink and my mind generates lots of possible solutions so I was not sure. I ended up replying "The Browser" and since this day I always wanted to research this further and see if this was correct or not :)

In this blog I will present my analysis on this and walk you through the DNS lookup process.

First we need to analyse each term in the question:

1. Who does? -> Do we mean initiate the call or do the actual lookup on the nameserver?
2. DNS Lookup -> An API call that takes as an argument a URL (e.g. petrospetrou.co.uk) and returns its IP address (e.g. 173.236.127.52).
3. Browser -> An application which provides access to the World Wide Web
4. Operating System -> This can be a bit complex to define. Do we mean just the kernel? Do we include standard libraries? More on this towards the end.

Now lets see how a DNS Lookup works...

When an application such as a web browser needs to resolve a hostname to an IP address it requires a DNS Lookup. This will query a name server and return the IP address of the hostname. A typical example is the dig utility.

```
[ppetrou@fedora root]$
[ppetrou@fedora root]$ dig www.petrospetrou.co.uk

; <<>> DiG 9.16.33-RH <<>> www.petrospetrou.co.uk
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 58067
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.petrospetrou.co.uk.		IN	A

;; ANSWER SECTION:
www.petrospetrou.co.uk.	672	IN	CNAME	petrospetrou.co.uk.
petrospetrou.co.uk.	146	IN	A	173.236.127.52

;; Query time: 0 msec
;; SERVER: 192.168.2.1#53(192.168.2.1)
;; WHEN: Sat Oct 08 21:00:56 BST 2022
;; MSG SIZE  rcvd: 99
```

But how is the DNS Lookup implemented?

In order to explain this we will see Linux as the OS and C as the language that the application is implemented. Something similar exists in other languages and Operating Systems but we have no access to their source code so we cannot elaborate further.

The [Standard C Library](https://www.gnu.org/software/libc/libc.html){:target="_blank"} has a header file [netdb.h](https://github.com/bminor/glibc/blob/master/resolv/netdb.h){:target="_blank"} with definitions for network database operations. This is part of the [resolver library](https://tldp.org/LDP/nag2/x-087-2-resolv.library.html){:target="_blank"} which includes the following two methods.

* gethostbyname()
* gethostbyaddr()

When an application requires a DNS Lookup it can use the gethostbyname() function in order to resolve the hostname. You can find a simple C program that does this [here](https://paulschreiber.com/blog/2005/10/28/simple-gethostbyname-example/){:target="_blank"}.

In order to see this in a known application we can search the [source code](http://invisible-island.net/datafiles/release/lynx-cur.zip){:target="_blank"} of the text based [Lynx](https://lynx.invisible-island.net/lynx.html){:target="_blank"} browser. I have no time to analyse the code properly but we can see that there are multiple references to the gethostbyname() function.

```
ppetrou@fedora lynx2.9.0dev.10]$ grep -R gethostbyname *
.
.
WWW/Library/Implementation/HTTCP.c:	gbl_phost = gethostbyname(host);
WWW/Library/Implementation/HTTCP.c:    gbl_phost = gethostbyname(host);
WWW/Library/Implementation/HTTCP.c:     * fork-based gethostbyname() with checks for interrupts.
WWW/Library/Implementation/HTTCP.c:			HTInetStatus("CHILD gethostbyname");
WWW/Library/Implementation/HTTCP.c:	    CTRACE((tfp, "%s: INTERRUPTED gethostbyname.\n", this_func));
WWW/Library/Implementation/HTTCP.c:static void really_gethostbyname(const char *host,
WWW/Library/Implementation/HTTCP.c:    phost = gethostbyname(host);
WWW/Library/Implementation/HTTCP.c:    CTRACE((tfp, "really_gethostbyname() returned %d\n", phost));
WWW/Library/Implementation/HTTCP.c:    dump_hostent("CHILD gethostbyname", phost);
WWW/Library/Implementation/HTTCP.c:/*	Resolve an internet hostname, like gethostbyname
WWW/Library/Implementation/HTTCP.c: *  gethostbyname(), except for the following:
WWW/Library/Implementation/HTTCP.c: *  If NSL_FORK is not used, the result of gethostbyname is returned
WWW/Library/Implementation/HTTCP.c:#ifdef MVS			/* Outstanding problem with crash in MVS gethostbyname */
WWW/Library/Implementation/HTTCP.c:    CTRACE((tfp, "%s: Calling gethostbyname(%s)\n", this_func, host));
WWW/Library/Implementation/HTTCP.c:    if (!setup_nsl_fork(really_gethostbyname,
WWW/Library/Implementation/HTTCP.c:		gbl_phost = gethostbyname(host);
WWW/Library/Implementation/HTTCP.c:	phost = gethostbyname(host);	/* See netdb.h */
WWW/Library/Implementation/HTTCP.c:	CTRACE((tfp, "%s: gethostbyname() returned %d\n", this_func, phost));
WWW/Library/Implementation/HTTCP.c:#ifdef MVS			/* Outstanding problem with crash in MVS gethostbyname */
WWW/Library/Implementation/HTTCP.c:    phost = gethostbyname(name);	/* See netdb.h */
WWW/Library/Implementation/HTTCP.h:/*	Resolve an internet hostname, like gethostbyname
WWW/Library/Implementation/HTTCP.h: *  The interface is intended to be the same as for gethostbyname(),
```

Taking things a bit further we can also search for the same in the linux kernel [source code](https://github.com/torvalds/linux){:target="_blank"} and see if there are any references there.

```
[ppetrou@fedora linux]$ ls
arch   certs    CREDITS  Documentation  fs       init      ipc     Kconfig  lib       MAINTAINERS  mm   README   scripts   sound  usr
block  COPYING  crypto   drivers        include  io_uring  Kbuild  kernel   LICENSES  Makefile     net  samples  security  tools  virt
[ppetrou@fedora linux]$
[ppetrou@fedora linux]$ grep -R gethostbyname *
[ppetrou@fedora linux]$
```

As expected no references exist so the browser does the DNS Lookup... or NOT?? :)

If we go back to the beginning of the blog where we analysed the terms of the question we see that we raised of few ambiguities...

If we consider that "does" means initiates then yes the browser does the DNS Lookup as the gethostbyname() function is called within the browser code.
On the contrary if "does" means the lookup of the host in the nameserver then this gets executed by the [resolver](https://tldp.org/LDP/nag2/x-087-2-resolv.library.html){:target="_blank"} which is part of the [Standard C Library](https://www.gnu.org/software/libc/libc.html){:target="_blank"} and is considered part of the operating system. It also cannot be removed as it includes lots of libraries such as the resolver or sudo, which could make the OS unusable. See below.

```
[root@lab1 ~]# sudo dnf remove glibc
Error:
 Problem: The operation would result in removing the following protected packages: sudo
(try to add '--skip-broken' to skip uninstallable packages or '--nobest' to use not only best candidate packages)
[root@lab1 ~]#
```

So the call sequence from the browser to the name server is the following:

```
Web browser -> glibc -> resolver -> gethostbyname() -> nameserver
```

Also what we have proved from this analysis is that the kernel DOES NOT do the DNS Lookup in any case!

I hope you enjoyed reading this blog as much I did when I was researching the topic. If you have any comments please leave them below.

Thank you,

Petros


<div id="commentics"></div>
