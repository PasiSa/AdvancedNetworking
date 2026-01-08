---
title: Introduction
---

The Advanced Networking course focuses on recent development of communication
networks and Internet protocols. We take a hands-on approach, with many of the
assignments involving practical experimentation and network programming tasks.
The course is divided in to 9 parts, including this introduction. Each part
comes with an assignment.

The hands-on assignments assume a Linux system and networking tools. As many do
not have native Linux machine available, you can use virtual machine for running
Linux for the exercises. We also use **[Mininet](https://mininet.org/)** to
emulate different network behaviors in our assignments. Therefore you should
start from the **[setup instructions](../environment/)**, that walk through how
to install the software needed on this course in a virtual (or native) Linux
environment.

We roughly move from the top of the networking stack towards the bottom, with a
few sidesteps. For an easy start, we get familiar with basic network programming
concepts, first with **[client socket programming](../socket-basics/)**, and
then moving to **[server programming](../server-sockets)**, with techniques to
handle concurrency efficiently at the server. We also briefly cover datagram
sockets and UDP. Most examples use the **[Rust](https://rust-lang.org/)**
programming language, as it is a modern, memory-safe language capable of
low-level programming that is gaining popularity in the networking community.

After some programming, we discuss **congestion control** in the Internet. Even
though it is a traditional topic already covered in typical elementary
networking course, there are some recent developments and new algorithms worth
discussing: for example, these days nearly all systems use the **CUBIC
congestion control algorithm** by default, which is rarely discussed in basic
courses. Also the network applies active queue management and explicit
congestion notifications, and we discuss also some other new congestion control
algorithms that can make use of these techniques.

We will then take a look at the recent developments in **web protocols**, in
particular HTTP. Web techniques on top of the HTTP protocol is not in the scope
of this course, but the protocol itself has gone through some significant
changes. The new version, HTTP/3 is transmitted over the UDP (instead of TCP),
or rather a new transport protocol on top of UDP called **QUIC**. Among many new
features, it separates the congestion control and connection management from
managing the multiple streams that compose the web content, and reduces the
latency of the communication in different ways. Datagram-based HTTP/3 enables
new application possibilities on top of the web protocol stack from Websockets
to different forms of proxying and tunneling, challenging the way we have
traditionally thought about traditional protocol layering.

We will discuss what happens inside the **Linux kernel**, and how the Linux
processes the network traffic: important data structures, buffering, and how
network drivers and **offloading** is used to optimize the communication
efficiency as the performance requirements are constantly increasing. We also
discuss the **Netfilter framework** that can be used for various kinds of
modular traffic management and how **network namespaces** can be used to build
virtual networks, for example for the purposes of containerization.

As networks have become more complex to manage with advanced requirements on
quality of service and traffic filtering, and cloud datacenters have become
common, making the network environment more dynamic, **software defined
networking** has been proposed to manage the complexity. In the SDN model,
instead of integrated vendor-specific manually configured hardware, there is a
uniform centralized control plane that operates the software-based switches in
its domain based on higher-level instructions from network administrators. We
will discuss the architectures for software defined networking, along with
couple of specific technologies: the **P4 language** used in SDN switches and
network devices and **Extended BPF (eBPF)** , a way to introduce programmability
and user-level interfaces to the network devices and different hook points
inside the operating system kernel.

Continuing from SDN, we will discuss **datacenter networks** that often leverage
SDN techniques, and the topologies and architectures typically applied in them.
Datacenter networks differ in many ways from the traditional Internet: the
network is typically under single administration, but has tight requirements on
the data transfer speeds, response times, and reliability. Because of the
specific features in datacenters, there are special ways to arrange the network
topologies, and the related routing and congestion control solutions are also
different, as we will discuss.

Finally, we discuss a couple of very different environments: **delay and
disruption-tolerant networks**, and **Internet of Things**. Delay-tolerant
networks are used in environments where the normal network infrastructure and
normal protocol solutions are not applicable, for example because the delays are
very long and network connectivity is failing frequently, such as in space. On
the other hand, some network environments have hard limitations on available
power and computational capacity, and those, too, need specific communication
solutions.

## Assignments

The assignment descriptions and other possible files needed for assignments are
under the
[assignments](https://github.com/PasiSa/AdvancedNetworking/tree/main/assignments)
folder in this git repository. Some assignments also contain code templates
implemented in Rust that can be used to help you to get started with the
assignment. You may use the templates or implement your own solution from scratch.

One option is to clone or fork this repository to your local system, after which
you can start modifying the provided assignment templates, and maintain your
work in a forked personal git repository. This makes it easier to synchronize
your modifications between different systems, for example if you want to develop
you assignment code in your native system and development tools, but run the
code in the virtual Linux guest, that is technically a different machine in your
system.

The following assignments are available. Before starting the assignments, you
should set up a Mininet-based **[exercise environment](../environment/)** used
in the assignments:

- [Simple client](../assignments/task-cli/)
- [TCP server](../assignments/task-srv/)
- [Data transfer using UDP](../assignments/task-udp/)
- _More will be coming later_
