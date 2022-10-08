---
layout: post
title:  "Who does the DNS Lookup? The browser or the operating system?"
date:   2022-10-08 14:00:00 +0100
categories: os
tags: dns, linux, resolver
---

A common interview question for infrastructure roles is "Who does the DNS Lookup? The browser or the Operating System". When I was asked this question
lots of years ago my mind started spinning and was doing endless loops on what is the correct answer! Either was looking possible and could not justify
what is the correct one. I ended up replying "The Browser" and was not sure if it was the correct answer but since this day I always wanted to research this further.

In this blog I will present my analysis on this and walk you through the DNS lookup process.

First we need to define each term in the question so there is no further confusion:

1. DNS Lookup -> An API call that takes as an argument a URL (e.g. petrospetrou.co.uk) and returns its IP address (e.g. 173.236.127.52).
2. Browser -> An application which provides access to the World Wide Web
3. Operating System -> This can be a bit complex to define, but for this context we will define the OS as the kernel. Lots can
support and are probably right that other libraries are part of the operating system, but this does not lie within the technical
nature of the question, or this is my understanding... :) I will elaborate a bit further on this at the end.

Now lets see how a DNS Lookup works...

When an application needs to resolve a hostname to an IP address it requires a DNS Lookup. This will query a name server and return the IP address
of the hostname. Typical examples are the nslookup and dig utilities. Both utilities do the DNS Lookup and just return the IP address in the standard output.

```
[ppetrou@fedora root]$ nslookup www.petrospetrou.co.uk
Server:		192.168.2.1
Address:	192.168.2.1#53

Non-authoritative answer:
www.petrospetrou.co.uk	canonical name = petrospetrou.co.uk.
Name:	petrospetrou.co.uk
Address: 173.236.127.52

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

In order to explain this we will see Linux as the OS and C as the application implementation language. Something similar exists in other languages and Operating Systems but we have no access to their source code so we cannot elaborate further.

The [Standard C Library](https://www.gnu.org/software/libc/libc.html){:target="_blank"} has a header file [netdb.h](https://github.com/bminor/glibc/blob/master/resolv/netdb.h){:target="_blank"} with definitions for network database operations. This is part of the [resolver library](https://tldp.org/LDP/nag2/x-087-2-resolv.library.html){:target="_blank"} which includes the following two methods.

* gethostbyname()
* gethostbyaddr()

When an application requires a DNS Lookup it can use the gethostbyname() function in order to resolve the hostname. You can find a simple C example [here](https://paulschreiber.com/blog/2005/10/28/simple-gethostbyname-example/){:target="_blank"}.

In order to see this in a known application we can search the [source code](http://invisible-island.net/datafiles/release/lynx-cur.zip){:target="_blank"} of the text based [Lynx](https://lynx.invisible-island.net/lynx.html){:target="_blank"} browser. I have no time to analyse the code properly but we can see that there are multiple
references to the gethostbyname() function.

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
[ppetrou@fedora linux]$ grep -R gethostbyname *
[ppetrou@fedora linux]$
```

As expected no references exist so the browser does the DNS Lookup... or NOT??

We can consider the above analysis correct and yes answer that the browser does the DNS Lookup BUT...

glibc which provides the gethostbyname and gethostbyaddr function is considered part of the operating system which in our analysis
we have left out as we defined the operating system as the kernel only!!

Also how do we interpret "Who does the DNS Lookup"?? Do we mean "initiate the lookup" or "query the name server"?
If we interpret it as initiate then the browser is the correct answer. On the other hand if we interpret it as query the name server
then it is the glibc which is considered part of the operating system :)

I hope you enjoyed reading this blog as much I did when I was researching the topic. If you have any comments please leave them below.

Thank you,

Petros


<div id="commentics"></div>
